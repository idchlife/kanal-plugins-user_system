# frozen_string_literal: true

require "fileutils"
require "active_record"
require "kanal/core/core"
require "kanal/plugins/user_system/models/kanal_user"
require "kanal/plugins/user_system/user_system_plugin"
require "kanal/plugins/active_record/active_record_plugin"

include Kanal::Plugins::UserSystem::Models

DB_FILEPATH = File.join __dir__, "../../../../tmp/db.sqlite"

RSpec.describe Kanal::Plugins::UserSystem::Models::KanalUser do
  before do
    FileUtils.rm_f DB_FILEPATH
  end

  def initialize_plugin
    core = Kanal::Core::Core.new

    core.register_plugin Kanal::Plugins::ActiveRecord::ActiveRecordPlugin.new(
      adapter: "sqlite3",
      database: DB_FILEPATH
    )
    core.register_plugin Kanal::Plugins::UserSystem::UserSystemPlugin.new
    active_record_plugin = core.get_plugin :active_record
    active_record_plugin.migrate
  end

  it "creates user, saves it and gets it back by its username" do
    initialize_plugin

    user = KanalUser.create username: "Bonjo"

    expect(user.new_record?).to eq false

    user = KanalUser.find_by username: "Bonjo"

    expect(user).not_to be_nil

    user = KanalUser.find_by username: "Gonjo"

    expect(user).to be_nil
  end

  it "creates user property, then changes it, checks if it changed" do
    initialize_plugin

    user = KanalUser.create username: "John Rico"

    user.create_or_update_property "favorite_food", "carrot"

    property_exists = false

    user.properties.each do |prop|
      property_exists = true if prop.name == "favorite_food" && prop.value == "carrot"
    end
  end

  it "creates several users with properties, tries to find them by properties, updates property, tries to find again" do
    initialize_plugin

    user1 = KanalUser.create username: "Vexel"
    user2 = KanalUser.create username: "Zaotsung"
    user3 = KanalUser.create username: "Wombat"

    user1.create_or_update_property "favorite_tree", "oak"
    user2.create_or_update_property "favorite_tree", "oak"
    user3.create_or_update_property "favorite_tree", "maple"

    oak_fans = KanalUser.find_all_by_property property_name: "favorite_tree", property_value: "oak"

    expect(oak_fans.size).to eq 2
    expect(oak_fans.find { |u| u.username == "Vexel" }).not_to be nil
    expect(oak_fans.find { |u| u.username == "Vexel" }).to be_instance_of KanalUser
    expect(oak_fans.find { |u| u.username == "Zaotsung" }).not_to be nil
    expect(oak_fans.find { |u| u.username == "Zaotsung" }).to be_instance_of KanalUser

    oak_fans = KanalUser.find_all_by_property property_name: "favorite_tree", property_value: "maple"

    expect(oak_fans.size).to eq 1
    expect(oak_fans.find { |u| u.username == "Wombat" }).not_to be nil
    expect(oak_fans.find { |u| u.username == "Wombat" }).to be_instance_of KanalUser

    users_with_favorite_tree = KanalUser.find_all_by_property property_name: "favorite_tree"

    expect(users_with_favorite_tree.size).to eq 3
    expect(users_with_favorite_tree.find { |u| u.username == "Vexel" }).not_to be nil
    expect(users_with_favorite_tree.find { |u| u.username == "Vexel" }).to be_instance_of KanalUser
    expect(users_with_favorite_tree.find { |u| u.username == "Zaotsung" }).not_to be nil
    expect(users_with_favorite_tree.find { |u| u.username == "Zaotsung" }).to be_instance_of KanalUser
    expect(users_with_favorite_tree.find { |u| u.username == "Wombat" }).not_to be nil
    expect(users_with_favorite_tree.find { |u| u.username == "Wombat" }).to be_instance_of KanalUser

    user1.create_or_update_property "favorite_tree", "birch"

    oak_fans = KanalUser.find_all_by_property property_name: "favorite_tree", property_value: "oak"

    expect(oak_fans.size).to eq 1
    expect(oak_fans.find { |u| u.username == "Zaotsung" }).not_to be nil
    expect(oak_fans.find { |u| u.username == "Zaotsung" }).to be_instance_of KanalUser
  end

  it "creates user state, checks it" do
    initialize_plugin

    user1 = KanalUser.create username: "Proper"
    user2 = KanalUser.create username: "Bloper"

    user1.state = "just_registered"
    user2.state = "about_to_upload_profile_photo"

    users_by_state = KanalUser.find_all_by_state "just_registered"

    expect(users_by_state.size).to eq 1

    expect(users_by_state.first.username).to eq "Proper"
  end
end
