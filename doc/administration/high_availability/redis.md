# Configuring Redis for GitLab HA

You can choose to install and manage Redis yourself, or you can use the one
that comes bundled with GitLab Omnibus packages.

> **Note:** Redis does not require authentication by default. See
  [Redis Security](http://redis.io/topics/security) documentation for more
  information. We recommend using a combination of a Redis password and tight
  firewall rules to secure your Redis service.

## Configure your own Redis server

If you're hosting GitLab on a cloud provider, you can optionally use a
managed service for Redis. For example, AWS offers a managed ElastiCache service
that runs Redis.

## Configure Redis using Omnibus

If you don't want to bother setting up your own Redis server, you can use the
one bundled with Omnibus. In this case, you should disable all services except
Redis.

1. Download/install GitLab Omnibus using **steps 1 and 2** from
   [GitLab downloads](https://about.gitlab.com/downloads). Do not complete other
   steps on the download page.
1. Create/edit `/etc/gitlab/gitlab.rb` and use the following configuration.
   Be sure to change the `external_url` to match your eventual GitLab front-end
   URL:

    ```ruby
    external_url 'https://gitlab.example.com'

    # Disable all services except Redis
    redis['enable'] = true
    bootstrap['enable'] = false
    nginx['enable'] = false
    unicorn['enable'] = false
    sidekiq['enable'] = false
    postgresql['enable'] = false
    gitlab_workhorse['enable'] = false
    mailroom['enable'] = false

    # Redis configuration
    redis['port'] = 6379
    redis['bind'] = '0.0.0.0'

    # If you wish to use Redis authentication (recommended)
    redis['password'] = 'redis-password-goes-here'
    ```

1. Run `sudo gitlab-ctl reconfigure` to install and configure PostgreSQL.

    > **Note**: This `reconfigure` step will result in some errors.
      That's OK - don't be alarmed.

1. Run `touch /etc/gitlab/skip-auto-migrations` to prevent database migrations
   from running on upgrade. Only the primary GitLab application server should
   handle migrations.

## Experimental Redis Sentinel support

> [Introduced][ce-1877] in GitLab 8.11.

Since GitLab 8.11, you can configure a list of Redis Sentinel servers that
will monitor a group of Redis servers to provide you with a standard failover
support.

There is currently one exception to the Sentinel support: `mail_room`, the
component that processes incoming emails. It doesn't support Sentinel yet, but
we hope to integrate a future release that does support it.

To get a better understanding on how to correctly setup Sentinel, please read
the [Redis Sentinel documentation](http://redis.io/topics/sentinel) first, as
failing to configure it correctly can lead to data loss.

The configuration consists of three parts:

- Redis setup
- Sentinel setup
- GitLab setup

Read carefully how to configure those components below.

### Redis setup

You must have at least 2 Redis servers: 1 Master, 1 or more Slaves.
They should be configured the same way and with similar server specs, as
in a failover situation, any Slave can be elected as the new Master by
the Sentinel servers.

In a minimal setup, the only required change for the slaves in `redis.conf`
is the addition of a `slaveof` line pointing to the initial master.
You can increase the security by defining a `requirepass` configuration in
the master, and `masterauth` in slaves.

---

**Configuring your own Redis server**

1. Add to the slaves' `redis.conf`:

    ```conf
    # IP and port of the master Redis server
    slaveof 10.10.10.10 6379
    ```

1. Optionally, set up password authentication for increased security.
   Add the following to master's `redis.conf`:

    ```conf
    # Optional password authentication for increased security
    requirepass "<password>"
    ```

1. Then add this line to all the slave servers' `redis.conf`:

    ```conf
    masterauth "<password>"
    ```

1. Restart the Redis services for the changes to take effect.

---

**Using Redis via Omnibus**

1. Edit `/etc/gitlab/gitlab.rb` of a master Redis machine (usualy a single machine):

    ```ruby
    ## Redis TCP support (will disable UNIX socket transport)
    redis['bind'] = '0.0.0.0' # or specify an IP to bind to a single one
    redis['port'] = 6379

    ## Master redis instance
    redis['password'] = 'redis-password-goes-here'
    ```

1. Edit `/etc/gitlab/gitlab.rb` of a slave Redis machine (should be one or more machines):

    ```ruby
    ## Redis TCP support (will disable UNIX socket transport)
    redis['bind'] = '0.0.0.0' # or specify an IP to bind to a single one
    redis['port'] = 6379

    ## Slave redis instance
    redis['master'] = false
    redis['master_ip'] = '10.10.10.10' # IP of master Redis server
    redis['master_port'] = 6379 # Port of master Redis server
    redis['master_password'] = "redis-password-goes-here"
    ```

1. Reconfigure the GitLab for the changes to take effect: `sudo gitlab-ctl reconfigure`

---

Now that the Redis servers are all set up, let's configure the Sentinel
servers.

### Sentinel setup

We provide an automated way to setup and run the Sentinel daemon
with GitLab EE.

To setup sentinel, you must edit `/etc/gitlab/gitlab.rb` file.
This is a minimal configuration required to run the daemon:


```ruby
##
## Replication support
##

# ...

## Slave and Sentinel shared configuration
## Both need to point to the master redis instance to get replication and heartbeat monitoring

redis['master_name'] = 'gitlab-redis' # must be the same in every sentinel node
# redis['master_ip'] = nil
# redis['master_port'] = nil
redis['master_password'] = 'your-secure-password-here' # the same value defined in redis['password'] in the master instance

########################
# GitLab Sentinel (EE) #
########################

## Make sure you configured all redis['master_*'] keys above before continuing.

sentinel['enable'] = true
# sentinel['port'] = 26379

## Quorum must reflect the amount of voting sentinels it take to start a failover.
# sentinel['quorum'] = 1

## Consider unresponsive server down after x amount of ms.
# sentinel['down_after_milliseconds'] = 10000

# sentinel['failover_timeout'] = 60000
```

If you want to install sentinel in a separate machine or control which other
services will be running in the same machine, take a look at the following
variables and enable or disable whenever it fits your strategy:

```ruby
# Disable all other services
redis['enable'] = false
bootstrap['enable'] = false
nginx['enable'] = false
unicorn['enable'] = false
sidekiq['enable'] = false
postgresql['enable'] = false
gitlab_workhorse['enable'] = false
mailroom['enable'] = false
```

---

The final part is to inform the main GitLab application server of the Redis
master and the new sentinels servers.

### GitLab setup

You can enable or disable sentinel support at any time in new or existing
installations. From the GitLab application perspective, all it requires is
the correct credentials for the master Redis and for a few Sentinel nodes.

It doesn't require a list of all Sentinel nodes, as in case of a failure,
the application will need to query only one of them.

>**Note:**
The following steps should be performed in the [GitLab application server](gitlab.md).

**For source based installations**

1. Edit `/home/git/gitlab/config/resque.yml` following the example in
   `/home/git/gitlab/config/resque.yml.example`, and uncomment the sentinels
   line, changing to the correct server credentials.
1. Restart GitLab for the changes to take effect.

**For Omnibus installations**

1. Edit `/etc/gitlab/gitlab.rb` and add/change the following lines:

    ```ruby
    redis['master_name'] = "gitlab-redis"
    redis['master_password'] = 'redis-password-goes-here'
    gitlab_rails['redis_sentinels'] = [ # list a few sentinels here (you don't need to list all of them)
      {'host' => '10.10.10.1', 'port' => 26379},
      {'host' => '10.10.10.2', 'port' => 26379},
      {'host' => '10.10.10.3', 'port' => 26379}
    ]
    ```

1. [Reconfigure] the GitLab for the changes to take effect.

### Sentinel troubleshooting

#### Omnibus install

If you get an error like: `Redis::CannotConnectError: No sentinels available.`,
there may be something wrong with your configuration files or it can be related
to [this issue][gh-531].

You must make sure you are defining the same value in `redis['master_name']`
and `redis['master_pasword']` as you defined for your sentinel node.

The way the redis connector `redis-rb` works with sentinel is a bit
non-intuitive. We try to hide the complexity in omnibus, but it still requires
a few extra configs.

#### Source install

If you get an error like: `Redis::CannotConnectError: No sentinels available.`,
there may be something wrong with your configuration files or it can be related
to [this issue][gh-531].

It's a bit non-intuitive the way you have to config `resque.yml` and
`sentinel.conf`, otherwise `redis-rb` will not work properly.

The `master-group-name` ('gitlab-redis') defined in (`sentinel.conf`)
**must** be used as the hostname in GitLab (`resque.yml` for source installations
or `gitlab-rails['redis_*']` in Omnibus):

```conf
# sentinel.conf:
sentinel monitor gitlab-redis 10.10.10.10 6379 1
sentinel down-after-milliseconds gitlab-redis 10000
sentinel config-epoch gitlab-redis 0
sentinel leader-epoch gitlab-redis 0
```

```yaml
# resque.yaml
production:
  url: redis://:myredispassword@gitlab-redis/
  sentinels:
    -
      host: slave1.example.com # or use ip
      port: 26380 # point to sentinel, not to redis port
    -
      host: slave2.exampl.com # or use ip
      port: 26381 # point to sentinel, not to redis port
```

When in doubt, please read [Redis Sentinel documentation](http://redis.io/topics/sentinel)

---

To make sure your configuration is correct:

1. SSH into your GitLab application server
1. Enter the Rails console:

    ```
    # For Omnibus installations
    sudo gitlab-rails console

    # For source installations
    sudo -u git rails console RAILS_ENV=production
    ```

1. Run in the console:

    ```ruby
    redis = Redis.new(Gitlab::Redis.params)
    redis.info
    ```

    Keep this screen open and try to simulate a failover below.

1. To simulate a failover on master Redis, SSH into the Redis server and run:

    ```bash
    # port must match your master redis port
     redis-cli -h localhost -p 6379 DEBUG sleep 60
    ```

1. Then back in the Rails console from the first step, run:

    ```
    redis.info
    ```

    You should see a different port after a few seconds delay
    (the failover/reconnect time).

---

Read more on high-availability configuration:

1. [Configure the database](database.md)
1. [Configure NFS](nfs.md)
1. [Configure the GitLab application servers](gitlab.md)
1. [Configure the load balancers](load_balancer.md)

[ce-1877]: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/1877
[restart]: ../restart_gitlab.md#installations-from-source
[reconfigure]: ../restart_gitlab.md#omnibus-gitlab-reconfigure
[gh-531]: https://github.com/redis/redis-rb/issues/531
[gh-534]: https://github.com/redis/redis-rb/issues/534
