# GitLab Geo database replication

>**Note:**
This is the documentation for the Omnibus GitLab packages. For installations
from source, follow the
[**database replication for installations from source**](database_source.md) guide.

1. [Install GitLab Enterprise Edition][install-ee] on the server that will serve
   as the secondary Geo node. Do not login or set up anything else in the
   secondary node for the moment.
1. **Setup the database replication (`primary (read-write) <-> secondary (read-only)` topology).**
1. [Configure GitLab](configuration.md) to set the primary and secondary nodes.
1. [Follow the after setup steps](after_setup.md).

[install-ee]: https://about.gitlab.com/downloads-ee/ "GitLab Enterprise Edition Omnibus packages downloads page"

This document describes the minimal steps you have to take in order to
replicate your GitLab database into another server. You may have to change
some values according to your database setup, how big it is, etc.

You are encouraged to first read through all the steps before executing them
in your testing/production environment.

## PostgreSQL replication

The GitLab primary node where the write operations happen will connect to
`primary` database server, and the secondary ones which are read-only will
connect to `secondary` database servers (which are read-only too).

>**Note:**
In many databases documentation you will see `primary` being references as `master`
and `secondary` as either `slave` or `standby` server (read-only).

### Prerequisites

The following guide assumes that:

- You are using PostgreSQL 9.2 or later which includes the
  [`pg_basebackup` tool][pgback]. If you are using Omnibus it includes the required
  PostgreSQL version for Geo.
- You have a primary server already set up (the GitLab server you are
  replicating from), running Omnibus' PostgreSQL (or equivalent version), and you
  have a new secondary server set up on the same OS and PostgreSQL version. If
  you are using Omnibus, make sure the GitLab version is the same on all nodes.
- The IP of the primary server for our examples will be `1.2.3.4`, whereas the
  secondary's IP will be `5.6.7.8`.

### Step 1. Configure the primary server

1. SSH into your GitLab **primary** server and login as root:

    ```
    sudo -i
    ```

1. Omnibus GitLab has already a replication user called `gitlab_replicator`.
   You must set its password manually. Replace `thepassword` with a strong
   password:

    ```bash
    sudo -u gitlab-psql /opt/gitlab/embedded/bin/psql -h /var/opt/gitlab/postgresql \
         -d template1 \
         -c "ALTER USER gitlab_replicator WITH ENCRYPTED PASSWORD 'thepassword'"
    ```

1. Edit `/etc/gitlab/gitlab.rb` and add the following:

    ```ruby
    geo_primary_role['enable'] = true
    postgresql['listen_address'] = "1.2.3.4"
    postgresql['trust_auth_cidr_addresses'] = ['127.0.0.1/32','1.2.3.4/32']
    postgresql['md5_auth_cidr_addresses'] = ['5.6.7.8/32']
    # postgresql['max_wal_senders'] = 10
    # postgresql['wal_keep_segments'] = 10
    ```

    Where `1.2.3.4` is the public IP address of the primary server, and `5.6.7.8`
    the public IP address of the secondary one.

    For security reasons, PostgreSQL by default only listens on the local
    interface (e.g. 127.0.0.1). However, GitLab Geo needs to communicate
    between the primary and secondary nodes over a common network, such as a
    corporate LAN or the public Internet. For this reason, we need to
    configure PostgreSQL to listen on more interfaces.

    The `listen_address` option opens PostgreSQL up to external connections
    with the interface corresponding to the given IP. See [the PostgreSQL
    documentation](https://www.postgresql.org/docs/9.6/static/runtime-config-connection.html)
    for more details.

    Note that if you are running GitLab Geo with a cloud provider (e.g. Amazon
    Web Services), the internal interface IP (as provided by `ifconfig`) may
    be different from the public IP address. For example, suppose you have a
    nodes with the following configuration:

    |Node Type|Internal IP|External IP|
    |---------|-----------|-----------|
    |Primary|10.1.5.3|54.193.124.100|
    |Secondary|10.1.10.5|54.193.100.155|

    In this case, for `1.2.3.4` use the internal IP of the primary node: 10.1.5.3.
    For `5.6.7.8`, use the external of the secondary node: 54.193.100.155.

    If you want to add another secondary, the relevant setting would look like:

    ```ruby
    postgresql['md5_auth_cidr_addresses'] = ['5.6.7.8/32','11.22.33.44/32']
    ```

    You may also want to edit the `wal_keep_segments` and `max_wal_senders` to
    match your database replication requirements. Consult the [PostgreSQL - Replication documentation](https://www.postgresql.org/docs/9.6/static/runtime-config-replication.html)
    for more information.

1. Check to make sure your firewall rules are set so that the secondary nodes
   can access port 5432 on the primary node.
1. Save the file and [reconfigure GitLab][] for the changes to take effect.
1. Now that the PostgreSQL server is set up to accept remote connections, run
   `netstat -plnt` to make sure that PostgreSQL is listening to the server's
   public IP.
1. Continue to [set up the secondary server](#step-2-configure-the-secondary-server).

### Step 2. Configure the secondary server

1. SSH into your GitLab **secondary** server and login as root:

    ```
    sudo -i
    ```

1. Test that the remote connection to the primary server works:

     ```
     sudo -u gitlab-psql /opt/gitlab/embedded/bin/psql -h 1.2.3.4 -U gitlab_replicator -d gitlabhq_production -W
     ```

    When prompted enter the password you set in the first step for the
    `gitlab_replicator` user. If all worked correctly, you should see the
    database prompt.

1. Exit the PostgreSQL console:

    ```
    \q
    ```

1. Edit `/etc/gitlab/gitlab.rb` and add the following:

    ```ruby
    geo_secondary_role['enable'] = true
    ```

1. [Reconfigure GitLab][] for the changes to take effect.
1. Continue to [initiate the replication process](#step-3-initiate-the-replication-process).

### Step 3. Initiate the replication process

Below we provide a script that connects to the primary server, replicates the
database and creates the needed files for replication.

The directories used are the defaults that are set up in Omnibus. If you have
changed any defaults or are using a source installation, configure it as you
see fit replacing the directories and paths.

>**Warning:**
Make sure to run this on the **secondary** server as it removes all PostgreSQL's
data before running `pg_basebackup`.

1. SSH into your GitLab **secondary** server and login as root:

    ```
    sudo -i
    ```

1. Execute the command below to start a backup/restore and begin the replication:

    ```
    gitlab-ctl replicate-geo-database --host=1.2.3.4
    ```

    Change the `--host=` to the primary node IP or FQDN. You can check other possible
    parameters with `--help`. When prompted, enter the password you set up for
    the `gitlab_replicator` user in the first step.

The replication process is now over.

### Next steps

Now that the database replication is done, the next step is to configure GitLab.

[➤ GitLab Geo configuration](configuration.md)

## MySQL replication

We don't support MySQL replication for GitLab Geo.

## Troubleshooting

Read the [troubleshooting document](troubleshooting.md).

[pgback]: http://www.postgresql.org/docs/9.2/static/app-pgbasebackup.html
[reconfigure GitLab]: ../administration/restart_gitlab.md#omnibus-gitlab-reconfigure
