# frozen_string_literal: true

require "kanal/core/plugins/plugin"
require_relative "./models/kanal_user"
require_relative "helpers/auto_creator"

module Kanal
  module Plugins
    module UserSystem
      # User system plugin serves as variant of user authentication,
      # registration and removal system
      class UserSystemPlugin < Kanal::Core::Plugins::Plugin
        include Models
        include Helpers

        attr_reader :auto_create

        #
        # @param [Boolean] auto_create Specify if auto-creation of users on incoming message will be used
        #
        def initialize(auto_create: false)
          super()
          @auto_create = AutoCreator.new if auto_create
        end

        def name
          :user_system
        end

        #
        # @param [Kanal::Core::Core] core <description>
        #
        # @return [void] <description>
        #
        def setup(core, auto_create: false)
          unless core.plugin_registered? :active_record
            raise "Cannot setup UserSystem without :active_record plugin installed!"
          end

          active_record_plugin = core.get_plugin :active_record

          active_record_plugin.add_migrations_directory File.join(__dir__, "migrations")

          setup_user_storage core
          setup_user_state core
        end

        def setup_user_state(core)
          user_exists = ->(i) { i.user.is_a? KanalUser }

          core.add_condition_pack :user_state do
            add_condition :is do
              with_argument

              met? do |input, core, argument|
                return false unless user_exists.call input

                check_for_state = argument

                check_for_state = check_for_state.to_s if check_for_state.is_a? Symbol

                current_state = input.user.state

                current_state == check_for_state
              end
            end

            add_condition :not_set do
              met? do |input, core, argument|
                return false unless user_exists.call input

                input.user.state.nil?
              end
            end
          end
        end

        def setup_user_storage(core)
          core.register_input_parameter :user

          user_exists = ->(i) { i.user.is_a? KanalUser }

          core.add_condition_pack :user do
            add_condition :exists do
              met? do |input, _, _|
                user_exists.call input
              end
            end

            add_condition :has_property_value do
              with_argument

              met? do |input, c, argument|
                return false unless user_exists.call input

                property_name = argument[0]
                value = argument[1]

                property = input.user.get_property_by_name property_name

                return false if property.nil?

                property_value = property.value

                return property_value == value
              end
            end

            add_condition :phone_one_of do
              with_argument

              met? do |input, _, argument|
                return false unless user_exists.call input

                argument.include? input.user.phone
              end
            end

            add_condition :email_one_of do
              with_argument

              met? do |input, _, argument|
                return false unless user_exists.call input

                argument.include? input.user.email
              end
            end

            add_condition :username_one_of do
              with_argument

              met? do |input, _, argument|
                return false unless user_exists.call input

                return argument.include? input.user.username
              end
            end
          end
        end
      end
    end
  end
end
