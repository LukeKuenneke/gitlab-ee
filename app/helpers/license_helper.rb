module LicenseHelper
  def current_active_user_count
    User.active.count
  end

  def license_message(signed_in: signed_in?, is_admin: (current_user && current_user.is_admin?))
    @license_message ||=
      if License.current
        yes_license_message(signed_in, is_admin)
      else
        no_license_message(signed_in, is_admin)
      end
  end

  private

  def no_license_message(signed_in, is_admin)
    message = []

    message << "No GitLab Enterprise Edition license has been provided yet."
    message << "Pushing code and creation of issues and merge requests has been disabled."

    message <<
      if is_admin
        "Upload a license in the admin area"
      else
        "Ask an admin to upload a license"
      end

    message << "to activate this functionality."

    message.join(" ")
  end

  def yes_license_message(signed_in, is_admin)
    license = License.current

    return unless signed_in

    return unless (is_admin && (license.notify_admins? || license.warn_upgrade_license_message?)) || license.notify_users?

    message = []

    unless license.warn_upgrade_license_message?
      message << "The GitLab Enterprise Edition license"
      message << (license.expired? ? "expired" : "will expire")
      message << "on #{license.expires_at}."
    end

    if license.expired? && license.will_block_changes?
      message << "Pushing code and creation of issues and merge requests"

      message <<
        if license.block_changes?
          "has been disabled."
        else
          "will be disabled on #{license.block_changes_at}."
        end

      message <<
        if is_admin
          "Upload a new license in the admin area"
        else
          "Ask an admin to upload a new license"
        end

      message << "to"
      message << (license.block_changes? ? "restore" : "ensure uninterrupted")
      message << "service."
    elsif license.warn_upgrade_license_message?
      message << "Your GitLab license currently covers #{license.user_count}"
      message << "users, but it looks like your site has grown to"
      message << "#{current_active_user_count} users. Please contact"
      message << "sales@gitlab.com to increase the seats on your license."
      message << "Thank you for choosing GitLab."
    end

    message.join(" ")
  end

  extend self
end
