# frozen_string_literal: true

require "active_record"
require_relative "./kanal_user_property"

module Kanal
  module Plugins
    module UserSystem
      module Models
        # Base user class for storing user properties
        class KanalUser < ActiveRecord::Base
          self.table_name = :kanal_users

          STATE_PROPERTY = "_state"

          has_many :kanal_user_properties

          #
          # Get all relatived properties for this user
          #
          # @return [Array<Kanal::Plugins::UserSystem::Models::KanalUserProperty>] <description>
          #
          def properties
            kanal_user_properties
          end

          #
          # Gets property by name if it exists for this user
          #
          # @param [String, Symbol] property_name <description>
          #
          # @return [Kanal::Plugins::UserSystem::Models::KanalUserProperty, nil] <description>
          #
          def get_property_by_name(property_name)
            KanalUserProperty.find_by(kanal_user_id: id, name: property_name)
          end

          #
          # Create KanalUserProperty and attach to this user
          # Value of property can be any value that can be serialized
          # and deserialized with JSON
          #
          # @param [String, Symbol] property_name <description>
          # @param [Object] property_value <description>
          #
          # @return [KanalUserProperty] created or updates property
          #
          def create_or_update_property(property_name, property_value)
            property = KanalUserProperty.find_by(kanal_user_id: id, name: property_name)

            property ||= KanalUserProperty.create(
              kanal_user_id: id,
              name: property_name,
              raw_value: JSON.generate(property_value)
            )

            property.value = property_value

            property.save
          end

          #
          # Get current users state
          #
          # @return [String] <description>
          #
          def state
            prop = get_property_by_name STATE_PROPERTY

            return nil if prop.nil?

            prop.value
          end

          #
          # Set state for user
          #
          # @param [String] value <description>
          #
          # @return [void] <description>
          #
          def state=(state_value)
            create_or_update_property STATE_PROPERTY, state_value
          end

          #
          # Find all users with needed state. It's possible to limit and offset
          #
          # @param [String] state_value <description>
          # @param [Integer] limit <description>
          # @param [Integer] offset <description>
          #
          # @return [Array<Kanal::Plugins::UserSystem::Models::KanalUser>] <description>
          #
          def self.find_all_by_state(state_value, limit: nil, offset: nil)
            find_all_by_property(
              property_name: STATE_PROPERTY,
              property_value: state_value,
              limit: limit,
              offset: offset
            )
          end

          #
          # Find all users that have the specified property.
          # If you also specify the property_value, you will get
          # users that also has the same value.
          # You can also optionally use limit and offset for pagination or simply getting
          # the preferred size of result
          #
          # @example
          #   users_with_big_nose = KanalUser.find_all_by_property(property_name: "nose", property_value: "big")
          #
          # @param [String, Symbol] property_name <description>
          # @param [Object] property_value <description>
          # @param [Integer] limit limit result
          # @param [Integer] offset offset for result
          #
          # @return [Array<Kanal::Plugins::UserSystem::Models::KanalUser>] <description>
          #
          def self.find_all_by_property(property_name:, property_value: nil, limit: nil, offset: nil)
            if !property_value.nil?
              users = KanalUser.includes(:kanal_user_properties).where(
                "kanal_user_properties.name" => property_name.to_s,
                "kanal_user_properties.raw_value" => JSON.generate(property_value)
              )
            else
              users = KanalUser.includes(:kanal_user_properties).where(
                "kanal_user_properties.name" => property_name.to_s
              )
            end

            users.limit(limit) unless limit.nil?
            users.offset(offset) unless offset.nil?

            users
          end
        end
      end
    end
  end
end
