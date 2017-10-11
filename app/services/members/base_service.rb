module Members
  class BaseService < ::BaseService
    include MembersHelper

    attr_accessor :source

    # source - The source object that respond to `#members` (i.g. project or group)
    # current_user - The user that performs the action
    # params - A hash of parameters
    def initialize(source, current_user, params = {})
      @source = source
      @current_user = current_user
      @params = params
    end
  end
end
