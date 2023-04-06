# frozen_string_literal: true

require "fileutils"
require "kanal/plugins/user_system/user_system_plugin"
require "kanal/plugins/user_system/models/kanal_user"
require "kanal/plugins/batteries/batteries_plugin"
require "kanal/core/core"

include Kanal::Plugins::UserSystem::Models

DB_FILEPATH = File.join(__dir__, "../../../tmp/db.sqlite")

RSpec.describe Kanal::Plugins::UserSystem::UserSystemPlugin do
  before do
    FileUtils.rm_f(DB_FILEPATH)
  end

  def initialize_plugin(auto_create: false)
    core = Kanal::Core::Core.new

    core.register_plugin Kanal::Plugins::Batteries::BatteriesPlugin.new

    core.register_plugin Kanal::Plugins::ActiveRecord::ActiveRecordPlugin.new(
      adapter: "sqlite3",
      database: DB_FILEPATH
    )

    if auto_create
      user_system = Kanal::Plugins::UserSystem::UserSystemPlugin.new auto_create: true
      user_system.auto_create.enable_telegram(core)
    else
      user_system = Kanal::Plugins::UserSystem::UserSystemPlugin.new
      core.register_plugin user_system
    end

    core.register_plugin user_system

    active_record_plugin = core.get_plugin :active_record
    active_record_plugin.migrate

    core
  end

  it "registered in kanal" do
    expect do
      initialize_plugin
    end.not_to raise_error
  end

  it "works with routing, checks user conditions" do
    core = initialize_plugin

    core.hooks.attach :input_just_created do |input|
      username = "John"

      user = KanalUser.find_by username: username

      user ||= KanalUser.create username: username

      input.user = user
    end

    core.router.default_response do
      body "Default response"
    end

    core.router.configure do
      on :user, :exists do
        on :body, contains: "set last_name " do
          respond do
            input.user.create_or_update_property "last_name", input.body.sub("set last_name ", "")

            body "Last name changed!"
          end
        end

        on :body, contains: "get last_name" do
          respond do
            body input.user.get_property_by_name("last_name").value
          end
        end

        on :user, has_property_value: ["last_name", "LookAtMyHorse"] do
          respond do
            body "You have it"
          end
        end

        on :flow, :any do
          respond do
            body "User exists!"
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

    expect(output.body).to include "User exists!"

    input = core.create_input
    input.body = "set last_name LookAtMyHorse"

    core.router.consume_input input

    expect(output.body).to include "Last name changed!"

    input = core.create_input
    input.body = "get last_name"

    core.router.consume_input input

    expect(output.body).to include "LookAtMyHorse"

    input = core.create_input

    core.router.consume_input input

    expect(output.body).to include "You have it"
  end

  it "works with user_state service, user state conditions, checks condition without user" do
    core = initialize_plugin

    core.register_input_parameter :chat_id

    core.hooks.attach :input_before_router do |input|
      return if input.chat_id.nil?

      user = KanalUser.find_all_by_property(property_name: "chat_id", property_value: input.chat_id).first

      if user.nil?
        user = KanalUser.create username: "TEMP_USERNAME_#{input.chat_id}"
        user.create_or_update_property "chat_id", input.chat_id
      end

      input.user = user
    end

    core.router.default_response do
      body "Default response"
    end

    core.router.configure do
      on :user, :exists do
        on :user_state, :not_set do
          respond do
            body "Welcome. Now you are required to enter your name"

            input.user.state = :just_registered
          end
        end

        on :user_state, is: :just_registered do
          respond do
            input.user.state = :awaiting_name

            body "Please provide your name"
          end
        end

        on :user_state, is: :awaiting_name do
          respond do
            input.user.create_or_update_property "name", input.body

            body "Nice, your name: #{input.body}"

            input.user.state = :main_menu
          end
        end

        on :user_state, is: :main_menu do
          respond do
            body "Main Menu"
          end
        end
      end

      on :flow, :any do
        respond do
          body "User does not exist"
        end
      end
    end

    output = nil

    core.router.output_ready do |o|
      output = o
    end

    input = core.create_input

    core.router.consume_input input

    expect(output.body).to include "User does not exist"

    input = core.create_input
    input.body = "/start"
    input.chat_id = 4444

    core.router.consume_input input
    expect(output.body).to include "Welcome. Now you are required to enter your name"

    input = core.create_input
    input.body "Well hello there"
    input.chat_id = 4444

    core.router.consume_input input

    expect(output.body).to include "Please provide your name"

    input = core.create_input
    input.body "John Rico"
    input.chat_id = 4444

    core.router.consume_input input

    expect(output.body).to eq "Nice, your name: John Rico"

    input = core.create_input
    input.body "Anything"
    input.chat_id = 4444

    core.router.consume_input input

    expect(output.body).to eq "Main Menu"

    input = core.create_input

    core.router.consume_input input

    expect(output.body).to eq "User does not exist"
  end

  it "works with auto creator" do
    core = initialize_plugin auto_create: true

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

      on :flow, :any do
        respond do
          body "User does not exist"
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
