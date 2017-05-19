# Usage statistics

GitLab Inc. will periodically collect information about your instance in order
to perform various actions.

All statistics are opt-out, you can disable them from the admin panel.

## Version check

GitLab can inform you when an update is available and the importance of it.

No information other than the GitLab version and the instance's domain name
are collected.

In the **Overview** tab you can see if your GitLab version is up to date. There
are three cases: 1) you are up to date (green), 2) there is an update available
(yellow) and 3) your version is vulnerable and a security fix is released (red).

In any case, you will see a message informing you of the state and the
importance of the update.

If enabled, the version status will also be shown in the help page (`/help`)
for all signed in users.

## Usage ping

> [Introduced][ee-557] in GitLab Enterprise Edition 8.10. More statistics
[were added][ee-735] in GitLab Enterprise Edition
8.12. [Moved to GitLab Community Edition][ce-23361] in 9.1.

<<<<<<< HEAD
GitLab Inc. can collect non-sensitive information about how GitLab users
use their GitLab instance upon the activation of a ping feature
located in the admin panel (`/admin/application_settings`).

You can see the **exact** JSON payload that your instance sends to GitLab
in the "Usage statistics" section of the admin panel.

Nothing qualitative is collected. Only quantitative. That means no project
names, author names, comment bodies, names of labels, etc.

The usage ping is sent in order for GitLab Inc. to have a better understanding
of how our users use our product, and to be more data-driven when creating or
changing features.

The total number of the following is sent back to GitLab Inc.:

- Comments
- Groups
- Users
- Projects
- Issues
- Labels
- CI builds
- Snippets
- Milestones
- Todos
- Pushes
- Merge requests
- Environments
- Triggers
- Deploy keys
- Pages
- Project Services
- Projects using the Prometheus service
- Issue Boards
- CI Runners
- Deployments
- Geo Nodes
- LDAP Groups
- LDAP Keys
- LDAP Users
- LFS objects
- Protected branches
- Releases
- Remote mirrors
- Service Desk projects
- Service Desk issues
- Uploads
- Web hooks

Also, we track if you've installed Mattermost with GitLab.
For example: `"mattermost_enabled":true"`.

More data will be added over time. The goal of this ping is to be as light as
possible, so it won't have any performance impact on your installation when
the calculation is made.
=======
GitLab sends a weekly payload containing usage data to GitLab Inc. The usage
ping uses high-level data to help our product, support, and sales teams. It does
not send any project names, usernames, or any other specific data. The
information from the usage ping is not anonymous, it is linked to the hostname
of the instance.

You can view the exact JSON payload in the administration panel.
>>>>>>> gl-ce/9-2-stable

### Deactivate the usage ping

By default, usage ping is opt-out. If you want to deactivate this feature, go to
the Settings page of your administration panel and uncheck the Usage ping
checkbox.

To disable the usage ping and prevent it from being configured in future through
the administration panel, Omnibus installs can set the following in
[`gitlab.rb`](https://docs.gitlab.com/omnibus/settings/configuration.html#configuration-options):

```ruby
gitlab_rails['usage_ping_enabled'] = false
```

And source installs can set the following in `gitlab.yml`:

```yaml
production: &base
  # ...
  gitlab:
    # ...
    usage_ping_enabled: false
```

[ee-557]: https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/557
[ee-735]: https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/735
[ce-23361]: https://gitlab.com/gitlab-org/gitlab-ce/issues/23361
