# frozen_string_literal: true

require "json"
require "active_record"

module Kanal
  module Plugins
    module UserSystem
      module Helpers
        # Helps using .value property with restoring/saving from
        # json representation in .raw_value model field
        module JsonValueConverterMixin
          def value
            JSON.parse(raw_value)
          end

          def value=(val)
            self.raw_value = JSON.generate(val)
          end
        end
      end
    end
  end
end
