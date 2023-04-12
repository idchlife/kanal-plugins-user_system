# frozen_string_literal: true

module Kanal
  module Plugins
    module UserSystem
      module Helpers
        #
        # Serves as a configuration storage for UserSystem plugin to allow enabling of automatic creation of users
        #
        class AutoCreateEnabler
          attr_reader :telegram_enabled

          def initialize
            @telegram_enabled = false
          end

          def enable_telegram
            @telegram_enabled = true
          end
        end
      end
    end
  end
end

