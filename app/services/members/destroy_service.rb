module Members
  class DestroyService < Members::BaseService
    ALLOWED_SCOPES = %i[members requesters all].freeze

    def execute(scope = :members)
      raise "scope :#{scope} is not allowed!" unless ALLOWED_SCOPES.include?(scope)

      member = find_member!(scope)

      raise Gitlab::Access::AccessDeniedError unless can_destroy_member?(member)

      AuthorizedDestroyService.new(member, current_user).execute

      unless member.request?
        AuditEventService.new(current_user, source, action: :destroy)
          .for_member(member).security_event
      end

      member
    end

    private

    def find_member!(scope)
      condition = params[:user_id] ? { user_id: params[:user_id] } : { id: params[:id] }
      case scope
      when :all
        source.members.find_by(condition) ||
          source.requesters.find_by!(condition)
      else
        source.public_send(scope).find_by!(condition) # rubocop:disable GitlabSecurity/PublicSend
      end
    end

    def can_destroy_member?(member)
      member && can?(current_user, action_member_permission(:destroy, member), member)
    end
  end
end
