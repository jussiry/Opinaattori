class Basic < ActiveRecord::Migration
  def self.up
    
    # USERS
    create_table :users do |t| #, :options => 'DEFAULT CHARSET=UTF8'
      t.string :login
      t.string :password
      t.string :email
      
      t.string :name
      t.integer :sex # 1 = mies, 2 = nainen
      t.date :birthdate
      t.string :url # homepage
      
      t.string :current_session_id  # säilötään nykyisen session tunnus, jotta voidaan tuhota uuden alkaessa
      
      t.timestamps
    end
    
    User.create :login => "eka", :password => Digest::SHA1.hexdigest('eka')
    
    # OPINIONS
    create_table :opinions do |t| #, :options => 'DEFAULT CHARSET=UTF8'
      t.string :text
      t.integer :creator_id
      t.integer :pos, :default => 0 #positives_count
      t.integer :neg, :default => 0 #negatives_count
      t.integer :hidden, :default => 0
      t.boolean :anonymous
      t.integer :comments_count, :default => 0
      
      t.timestamps
    end
    
    # OPINION_STATUS
    create_table :opinion_statuses do |t| #, :options => 'DEFAULT CHARSET=UTF8'
      t.integer :opinion_id
      t.integer :user_id
      t.integer :status, :default => 0 # 1 = agree, 2 = disagree, 3 = hidden
      t.integer :hidden_counter, :default => 0
      t.boolean :anonymous
      
      t.timestamps
    end
    
    # TAGS
    create_table :tags do |t| #, :options => 'DEFAULT CHARSET=UTF8'
      t.string :name
      t.integer :user_id
      t.integer :opinion_id
      
      t.timestamps
    end
    
    # COMMENTS
    create_table :comments do |t| #, :options => 'DEFAULT CHARSET=UTF8'
      t.text :text   # TÄN EI PITÄS OLLA STRING VAAN TEXT?! TAI JOKIN MIKÄ TEKEE PITEMMÄN KUIN 255 merkkiä
      t.integer :opinion_id
      t.integer :user_id
      t.integer :reply_id
      t.boolean :anonymous
      
      t.timestamps
    end
  end

  def self.down
    drop_table :users
    drop_table :opinions
    drop_table :opinion_statuses
    drop_table :tags
    drop_table :comments
  end
end
