# Continuous integration Admin settings

## Maximum artifacts size

The maximum size of the [job artifacts][art-yml] can be set in the Admin area
of your GitLab instance. The value is in MB and the default is 100MB. Note that
this setting is set for each job.

1. Go to the **Admin area ➔ Settings** (`/admin/application_settings`).

    ![Admin area settings button](img/admin_area_settings_button.png)

1. Change the value of maximum artifacts size (in MB):

    ![Admin area maximum artifacts size](img/admin_area_maximum_artifacts_size.png)

1. Hit **Save** for the changes to take effect.

## Default artifacts expiration

> [Introduced][ee-1078] in GitLab Enterprise Edition 8.16.

The default expiration time of the [job artifacts][art-yml] can be set in
the Admin area of your GitLab instance. The syntax of duration is described
in [artifacts:expire_in][duration-syntax]. The default is `30 days`. Note that
this setting is set for each job. Set it to 0 if you don't want default
expiration.

1. Go to **Admin area > Settings** (`/admin/application_settings`).

    ![Admin area settings button](img/admin_area_settings_button.png)

1. Change the value of default expiration time ([syntax][duration-syntax]):

    ![Admin area default artifacts expiration](img/admin_area_default_artifacts_expiration.png)

1. Hit **Save** for the changes to take effect.

<<<<<<< ba4fe08c432bf5d296367405061491193b91cf76
---

While the setting in the Admin area has a global effect, as an admin you can
also change each group's build minutes quota to override the global value.

1. Navigate to the **Groups** admin area and hit the **Edit** button for the
   group you wish to change the build minutes quota.

    ![Groups in the admin area](img/admin_area_groups.png)

1. Set the build minutes quota to the desired value and hit **Save changes** for
   the changes to take effect.

    ![Edit group in the admin area](img/admin_area_group_edit.png)

Once saved, you can see the build quota in the group admin view.

![Group admin info](img/group_quota_view.png)

The quota can also be viewed in the project admin view if shared Runners
are enabled.

![Project admin info](img/admin_project_quota_view.png)

When the build minutes quota for a group is set to a value different than 0,
the **Pipelines quota** page is available to the group page settings list.

![Group settings](img/group_settings.png)

You can see there an overview of the build minutes quota of all projects of
the group.

![Group pipelines quota](img/group_pipelines_quota.png)

[art-yml]: ../../../administration/job_artifacts.md
[duration-syntax]: ../../../ci/yaml/README.md#artifactsexpire_in
