# frozen_string_literal: true

class AddAppleUidToUsers < ActiveRecord::Migration[7.1]
  def change
    change_table :users, bulk: true do |t|
      t.string :apple_uid
      t.index :apple_uid
    end
  end
end
