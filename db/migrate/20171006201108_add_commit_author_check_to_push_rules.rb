# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddCommitAuthorCheckToPushRules < ActiveRecord::Migration
  DOWNTIME = false

  def change
    add_column :push_rules, :commit_author_check, :boolean
  end
end
