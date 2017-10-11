module EE
  module Groups
    module GroupMembersController
      def override
        result = Members::UpdateService.new(@group, current_user, override_params)
          .execute(permission: :override)

        if result[:status] == :success
          respond_to do |format|
            format.js { head :ok }
          end
        end
      end

      protected

      def authorize_update_group_member!
        unless can?(current_user, :admin_group_member, group) || can?(current_user, :override_group_member, group)
          render_403
        end
      end

      def override_params
        params.require(:group_member).permit(:override)
      end
    end
  end
end
