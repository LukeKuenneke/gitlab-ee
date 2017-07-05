module Ci
  class Variable < ActiveRecord::Base
    extend Ci::Model
    include HasVariable

    belongs_to :project

    validates :key, uniqueness: { scope: [:project_id, :environment_scope] }

    scope :unprotected, -> { where(protected: false) }
  end
end
