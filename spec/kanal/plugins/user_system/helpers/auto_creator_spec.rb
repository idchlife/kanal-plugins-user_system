# frozen_string_literal: true

require "fileutils"
require "kanal/plugins/user_system/user_system_plugin"
require "kanal/plugins/user_system/helpers/auto_creator"
require "kanal/plugins/batteries/batteries_plugin"
require "kanal/core/core"

include Kanal::Plugins::UserSystem::Models

DB_FILEPATH = File.join(__dir__, "../../../../tmp/db.sqlite")

RSpec.describe Kanal::Plugins::UserSystem::Helpers::AutoCreator do
  before do
    FileUtils.rm_f(DB_FILEPATH)
  end

  def initialize_core
    core = Kanal::Core::Core.new

    core.register_plugin Kanal::Plugins::Batteries::BatteriesPlugin.new

    core.register_plugin Kanal::Plugins::ActiveRecord::ActiveRecordPlugin.new(
      adapter: "sqlite3",
      database: DB_FILEPATH
    )

    user_system = Kanal::Plugins::UserSystem::UserSystemPlugin.new
    user_system.auto_create.enable_telegram
    core.register_plugin user_system

    active_record_plugin = core.get_plugin :active_record
    active_record_plugin.migrate

    core
  end

  it "tests auto creation of tg users" do
    core = initialize_core

    core.register_input_parameter :tg_chat_id
    core.register_input_parameter :tg_username

    core.router.default_response do
      body "Default response"
    end

    core.router.configure do
      on :user, :exists do
        on :user_state, :not_set do
          respond do
            body "Welcome"
          end
        end
      end
    end

    output = nil

    core.router.output_ready do |o|
      output = o
    end

    input = core.create_input

    core.router.consume_input input

    input = core.create_input
    input.body = "/start"
    input.tg_chat_id = 4444

    core.router.consume_input input
    expect(output.body).to include "Welcome"
    expect(KanalUser.first.username).to eq "TEMP_USERNAME_4444"

    input = core.create_input
    input.body = "/start"
    input.tg_chat_id = 55555
    input.tg_username = "Something"

    core.router.consume_input input
    expect(KanalUser.last.username).to eq "Something"
  end
end