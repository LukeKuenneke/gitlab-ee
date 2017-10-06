# GitLab Geo database replication

>**Note:**
This is the documentation for installations from source. For installations
using the Omnibus GitLab packages, follow the
[**database replication for Omnibus GitLab**](database.md) guide.

1. [Install GitLab Enterprise Edition][install-ee-source] on the server that
   will serve as the secondary Geo node. Do not login or set up anything else
   in the secondary node for the moment.
1. **Setup the database replication topology:** `primary (read-write) <-> secondary (read-only)`
1. [Configure GitLab](configuration_source.md) to set the primary and secondary
   nodes.
1. [Follow the after setup steps](after_setup.md).

[install-ee-source]: https://docs.gitlab.com/ee/install/installation.html "GitLab Enterprise Edition installation from source"

This document describes the minimal steps you have to take in order to
replicate your GitLab database into another server. You may have to change
some values according to your database setup, how big it is, etc.

You are encouraged to first read through all the steps before executing them
in your testing/production environment.

## PostgreSQL replication

The GitLab primary node where the write operations happen will connect to
primary database server, and the secondary ones which are read-only will
connect to secondary database servers (which are read-only too).

>**Note:**
In many databases documentation you will see "primary" being referenced as "master"
and "secondary" as either "slave" or "standby" server (read-only).

Since GitLab 9.4: We recommend using [PostgreSQL replication
slots](https://medium.com/@tk512/replication-slots-in-postgresql-b4b03d277c75)
to ensure the primary retains all the data necessary for the secondaries to
recover. See below for more details.

### Prerequisites

The following guide assumes that:

- You are using PostgreSQL 9.6 or later which includes the
  [`pg_basebackup` tool][pgback] and improved [Foreign Data Wrapper][FDW] support. If you are using Omnibus it includes the required
  PostgreSQL version for Geo.
- You have a primary server already set up (the GitLab server you are
  replicating from), and you have a new secondary server set up on the same OS
  and PostgreSQL version. Also make sure the GitLab version is the same on all nodes.
- The IP of the primary server for our examples will be `1.2.3.4`, whereas the
  secondary's IP will be `5.6.7.8`. Note that the primary and secondary servers
  **must** be able to communicate over these addresses. These IP addresses can either
  be public or private.

### Step 1. Configure the primary server

1. SSH into your GitLab **primary** server and login as root:

    ```bash
    sudo -i
    ```

1. Create a replication user named `gitlab_replicator`:

    ```bash
    sudo -u postgres psql -c "CREATE USER gitlab_replicator REPLICATION ENCRYPTED PASSWORD 'thepassword';"
    ```

1. Edit `postgresql.conf` to configure the primary server for streaming replication
   (for Debian/Ubuntu that would be `/etc/postgresql/9.x/main/postgresql.conf`):

    ```bash
    listen_address = '1.2.3.4'
    wal_level = hot_standby
    max_wal_senders = 5
    min_wal_size = 80MB
    max_wal_size = 1GB
    max_replicaton_slots = 1 # Number of Geo secondary nodes
    wal_keep_segments = 10
    hot_standby = on
    ```

    Be sure to set `max_replication_slots` to the number of Geo secondary
    nodes that you may potentially have (at least 1).

    See the Omnibus notes above for more details of `listen_address`.

    You may also want to edit the `wal_keep_segments` and `max_wal_senders` to
    match your database replication requirements. Consult the [PostgreSQL - Replication documentation](https://www.postgresql.org/docs/9.6/static/runtime-config-replication.html)
    for more information.

1. Set the access control on the primary to allow TCP connections using the
   server's public IP and set the connection from the secondary to require a
   password.  Edit `pg_hba.conf` (for Debian/Ubuntu that would be
   `/etc/postgresql/9.x/main/pg_hba.conf`):

    ```bash
    host    all             all                      127.0.0.1/32    trust
    host    all             all                      1.2.3.4/32      trust
    host    replication     gitlab_replicator        5.6.7.8/32      md5
    ```

    Where `1.2.3.4` is the public IP address of the primary server, and `5.6.7.8`
    the public IP address of the secondary one. If you want to add another
    secondary, add one more row like the replication one and change the IP
    address:

      ```bash
      host    all             all                      127.0.0.1/32    trust
      host    all             all                      1.2.3.4/32      trust
      host    replication     gitlab_replicator        5.6.7.8/32      md5
      host    replication     gitlab_replicator        11.22.33.44/32  md5
      ```

1. Restart PostgreSQL for the changes to take effect.

1. Choose a database-friendly name to use for your secondary to use as the
   replication slot name. For example, if your domain is
   `geo-secondary.mydomain.com`, you may use `geo_secondary_my_domain_com` as
   the slot name.

1. Create the replication slot on the primary:

     ```bash
     $ sudo -u postgres psql -c "SELECT * FROM pg_create_physical_replication_slot('geo_secondary_my_domain');"
           slot_name             | xlog_position
        -------------------------+---------------
         geo_secondary_my_domain |
        (1 row)
     ```

1. Now that the PostgreSQL server is set up to accept remote connections, run
   `netstat -plnt` to make sure that PostgreSQL is listening to the server's
   public IP.
1. Continue to [set up the secondary server](#step-2-configure-the-secondary-server).

### Step 2. Configure the secondary server

1. SSH into your GitLab **secondary** server and login as root:

    ```bash
    sudo -i
    ```

1. Test that the remote connection to the primary server works:

    ```bash
    sudo -u postgres psql -h 1.2.3.4 -U gitlab_replicator -d gitlabhq_production -W
    ```

    When prompted enter the password you set in the first step for the
    `gitlab_replicator` user. If all worked correctly, you should see the
    database prompt.

1. Exit the PostgreSQL console:

    ```
    \q
    ```

1. Edit `postgresql.conf` to configure the secondary for streaming replication
   (for Debian/Ubuntu that would be `/etc/postgresql/9.*/main/postgresql.conf`):

    ```bash
    wal_level = hot_standby
    max_wal_senders = 5
    checkpoint_segments = 10
    wal_keep_segments = 10
    hot_standby = on
    ```

1. Restart PostgreSQL for the changes to take effect.

1. Optional since GitLab 9.1, and required for GitLab 10.0 or higher:
   [Enable tracking database on the secondary server](#enable-tracking-database-on-the-secondary-server)

1. Otherwise, continue to [initiate the replication process](#step-3-initiate-the-replication-process).

#### Enable tracking database on the secondary server

Geo secondary nodes use a tracking database to keep track of replication status and recover
automatically from some replication issues. This is a separate PostgreSQL instance running for each
secondary node.

It is added in GitLab 9.1, and since GitLab 10.0 it is required.

> **IMPORTANT:** For this feature to work correctly, all nodes must be
with their clocks synchronized. It is not required for all nodes to be set to
the same time zone, but when the respective times are converted to UTC time,
the clocks must be synchronized to within 60 seconds of each other.

1. Setup clock synchronization service in your Linux distro.
   This can easily be done via any NTP-compatible daemon. For example,
   here are [instructions for setting up NTP with Ubuntu](https://help.ubuntu.com/lts/serverguide/NTP.html).

1. Install this new instance (on the same machine, or in a separate machine i
   n a HA configuration). Use the same version as the other replicated database
   for feature parity.

1. Create `database_geo.yml` with the information of your additional PostgreSQL
   database. This is where the secondary will track its internal
   state:

    ```
    sudo cp /home/git/gitlab/config/database_geo.yml.postgresql /home/git/gitlab/config/database_geo.yml
    ```

1. Edit the content of `database_geo.yml` in `production:` like the example below:

     ```yaml
     #
     # PRODUCTION
     #
     production:
       adapter: postgresql
       encoding: unicode
       database: gitlabhq_geo_production
       pool: 10
       username: gitlab_geo
       # password:
       host: /var/opt/gitlab/geo-postgresql
     ```

1. Create the database `gitlabhq_geo_production` in that PostgreSQL
   instance.

1. Set up the Geo tracking database:

    ```bash
    bundle exec rake geo:db:migrate
    ```
     
1. Enable the [PostgreSQL FDW][FDW] extension:

    ```bash
    $ sudo -u postgres psql -d gitlabhq_geo_production -c "CREATE EXTENSION postgres_fdw;"
    ```

1. Configure the [PostgreSQL FDW][FDW] connection and credentials:

    ```bash
    $ sudo -u postgres psql -d gitlabhq_geo_production -c "CREATE SERVER gitlab_secondary FOREIGN DATA WRAPPER postgres_fdw OPTIONS (host 'localhost', port '5432', dbname 'gitlabhq_production');"
    $ sudo -u postgres psql -d gitlabhq_geo_production -c "CREATE USER MAPPING FOR CURRENT_USER SERVER gitlab_secondary OPTIONS (user 'gitlab', password 'mydatabasepassword');"
    $ sudo -u postgres psql -d gitlabhq_geo_production -c "CREATE SCHEMA gitlab_secondary;"
    ```

### Step 3. Initiate the replication process

Below we provide a script that connects to the primary server, replicates the
database and creates the needed files for replication.

The directories used are the defaults for Debian/Ubuntu. If you have changed
any defaults, configure it as you see fit replacing the directories and paths.

>**Warning:**
Make sure to run this on the **secondary** server as it removes all PostgreSQL's
data before running `pg_basebackup`.

1. SSH into your GitLab **secondary** server and login as root:

    ```bash
    sudo -i
    ```

1. Save the snippet below in a file, let's say `/tmp/replica.sh`:

    ```bash
    #!/bin/bash

    PORT="5432"
    USER="gitlab_replicator"
    echo ---------------------------------------------------------------
    echo WARNING: Make sure this scirpt is run from the secondary server
    echo ---------------------------------------------------------------
    echo
    echo Enter the IP of the primary PostgreSQL server
    read HOST
    echo Enter the password for $USER@$HOST
    read -s PASSWORD

    echo Stopping PostgreSQL and all GitLab services
    gitlab-ctl stop

    echo Backing up postgresql.conf
    sudo -u gitlab-psql mv /var/opt/gitlab/postgresql/data/postgresql.conf /var/opt/gitlab/postgresql/

    echo Cleaning up old cluster directory
    sudo -u gitlab-psql rm -rf /var/opt/gitlab/postgresql/data
    rm -f /tmp/postgresql.trigger

    echo Starting base backup as the replicator user
    echo Enter the password for $USER@$HOST
    sudo -u gitlab-psql /opt/gitlab/embedded/bin/pg_basebackup -h $HOST -D /var/opt/gitlab/postgresql/data -U gitlab_replicator -v -x -P

    echo Writing recovery.conf file
    sudo -u gitlab-psql bash -c "cat > /var/opt/gitlab/postgresql/data/recovery.conf <<- _EOF1_
      standby_mode = 'on'
      primary_conninfo = 'host=$HOST port=$PORT user=$USER password=$PASSWORD'
      trigger_file = '/tmp/postgresql.trigger'
    _EOF1_
    "

    echo Restoring postgresql.conf
    sudo -u gitlab-psql mv /var/opt/gitlab/postgresql/postgresql.conf /var/opt/gitlab/postgresql/data/

    echo Starting PostgreSQL and all GitLab services
    gitlab-ctl start
    ```

1. Run it with:

    ```bash
    bash /tmp/replica.sh
    ```

    When prompted, enter the password you set up for the `gitlab_replicator`
    user in the first step.

The replication process is now over.

### Next steps

Now that the database replication is done, the next step is to configure GitLab.

[➤ GitLab Geo configuration](configuration_source.md)

## MySQL replication

We don't support MySQL replication for GitLab Geo.

## Troubleshooting

Read the [troubleshooting document](troubleshooting.md).

[pgback]: http://www.postgresql.org/docs/9.6/static/app-pgbasebackup.html
[reconfigure GitLab]: ../administration/restart_gitlab.md#omnibus-gitlab-reconfigure
[FDW]: https://www.postgresql.org/docs/9.6/static/postgres-fdw.html
