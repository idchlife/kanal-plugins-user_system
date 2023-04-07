# frozen_string_literal: true

module Kanal
  module Plugins
    module UserSystem
      module Helpers
        class AutoCreate
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

