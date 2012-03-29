class CreateLogs < ActiveRecord::Migration
  def change
    create_table :logs do |t|
      t.datetime :date, :null => false
      t.string :client, :null => false
      t.string :query, :null => false
      t.string :q_type, :null => false
      t.string :server, :null => false
    end
  end
end