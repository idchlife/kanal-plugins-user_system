# frozen_string_literal: true

require "active_record"
require_relative "../helpers/json_value_converter_mixin"

module Kanal
  module Plugins
    module UserSystem
      module Models
        # Base user class for storing user properties
        class KanalUserProperty < ::ActiveRecord::Base
          include Helpers::JsonValueConverterMixin

          self.table_name = :kanal_user_properties

          belongs_to :kanal_users
        end
      end
    end
  end
end
