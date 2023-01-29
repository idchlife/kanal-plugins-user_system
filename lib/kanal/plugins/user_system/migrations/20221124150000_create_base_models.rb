# frozen_string_literal: true

require "active_record"

class CreateBaseModels < ::ActiveRecord::Migration[7.0]
  def change
    create_table :kanal_users do |t|
      t.string :username, null: false, index: { unique: true, name: "kanal_unique_usernames" }
      t.string :phone, null: true
      t.string :email, null: true

      t.timestamps
    end

    create_table :kanal_user_properties do |t|
      t.string :name, null: false
      t.string :raw_value, null: false
      # t.string :type, null: false

      t.timestamps
    end

    add_belongs_to :kanal_user_properties, :kanal_user, null: false, foreign_key: true

    add_index :kanal_user_properties, [:name, :kanal_user_id], unique: true
  end
end
