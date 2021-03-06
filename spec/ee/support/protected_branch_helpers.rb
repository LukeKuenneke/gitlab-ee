module EE
  module ProtectedBranchHelpers
    def set_allowed_to(operation, option = 'Masters', form: '.js-new-protected-branch')
      within form do
        find(".js-allowed-to-#{operation}").trigger('click')
        wait_for_requests

        Array(option).each { |opt| click_on(opt) }

        find(".js-allowed-to-#{operation}").trigger('click') # needed to submit form in some cases
      end
    end
  end
end
