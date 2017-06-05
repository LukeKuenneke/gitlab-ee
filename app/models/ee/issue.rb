module EE
  module Issue
    extend ActiveSupport::Concern

    prepended do
      has_many :referenced_issue_links, class_name: 'IssueLink', foreign_key: :source_id
      has_many :referred_by_issue_links, class_name: 'IssueLink', foreign_key: :target_id
      has_many :referenced_issues, through: :referenced_issue_links, source: :target
      has_many :referred_by_issues, through: :referred_by_issue_links, source: :source
    end

    # override
    def check_for_spam?
      author.support_bot? || super
    end

    # override
    def subscribed_without_subscriptions?(user, *)
      # TODO: this really shouldn't be necessary, because the support
      # bot should be a participant (which is what the superclass
      # method checks for). However, the support bot gets filtered out
      # at the end of Participable#raw_participants as not being able
      # to read the project. Overriding *that* behavior is problematic
      # because it doesn't use the Policy framework, and instead uses a
      # custom-coded Ability.users_that_can_read_project, which is...
      # a pain to override in EE. So... here we say, the support bot
      # is subscribed by default, until an unsubscribed record appears,
      # even though it's not *technically* a participant in this issue.

      # Making the support bot subscribed to every issue is not as bad as it
      # seems, though, since it isn't permitted to :receive_notifications,
      # and doesn't actually show up in the participants list.
      user.support_bot? || super
    end
  end
end
