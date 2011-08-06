class CreatePictures < ActiveRecord::Migration
  def self.up
    create_table :pictures do |t|
      t.string :picture_type
      t.binary :picture_data
      
      t.timestamps
    end
    
    # to users table:
    add_column :users, :small_picture_id, :string
    add_column :users, :op_picture_id, :string
    add_column :users, :picture_id, :string
    add_column :users, :large_picture_id, :string
  end

  def self.down
    drop_table :pictures
    
    remove_column :users, :picture_id
    remove_column :users, :small_picture_id
    remove_column :users, :large_picture_id
  end
end
