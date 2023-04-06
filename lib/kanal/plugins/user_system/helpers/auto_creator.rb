# frozen_string_literal: true

module Kanal
  module Plugins
    module UserSystem
      module Helpers
        class AutoCreator
          # Activates creation of user with telegram_chat_id property during input consuming
          def enable_telegram(core)
            core.hooks.attach :input_before_router do |input|
              tg_chat_id = input.tg_chat_id

              tg_chat_id_property = "telegram_chat_id"

              return if tg_chat_id.nil?

              user = KanalUser.find_all_by_property(property_name: tg_chat_id_property, property_value: tg_chat_id).first

              unless user
                username = input.tg_username

                username ||= "TEMP_USERNAME_#{tg_chat_id}"

                user = KanalUser.create(username: username)
                user.create_or_update_property(tg_chat_id_property, tg_chat_id)
              end

              input.user = user
            end
          end
        end
      end
    end
  end
end

