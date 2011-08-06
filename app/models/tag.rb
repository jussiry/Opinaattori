class Tag < ActiveRecord::Base
  belongs_to :user
  belongs_to :opinion
  validates_presence_of :user, :opinion
  
  def self.tag_hash
    
#    Rails.cache.delete("tag_hash")
    Rails.cache.fetch("tag_hash") do  #, :expires_in => 200.minutes
      tag_hash = {} # [tag_name][[op_id1],[op_id2]...]
      Tag.all.each do |tag|
        if tag_hash.has_key? tag.name
          tag_hash[tag.name] << tag.opinion_id unless tag_hash[tag.name].include?(tag.opinion_id)
          # sama tagi voi olla monta kertaa samassa mielipiteessä (eri käyttäjiltä), joten pitää varmistaa että sitä ei ole vielä listätty (unless ..)
        else
          tag_hash[tag.name] = [tag.opinion_id]
        end
      end
      # cache deletoidaan aina kun lisätään uusi tägi jonnekkin,
      # paitsi jos siitä on kulunut alle tunti:
      Rails.cache.write("tag_hash_updated", Time.now)
      
      tag_hash
    end
  end
  
  def self.top_tags
    # cache deletoidaan aina kun lisätään uusi tägi jonnekkin,
    # paitsi jos siitä on kulunut allet tunti (katotaan tag_hash_updatesta)
#    Rails.cache.delete("top_tags")
    Rails.cache.fetch("top_tags") do # , :expires_in => 201.minutes
      tag_array = tag_hash.to_a
      tag_array.sort { |a,b| b[1].size <=> a[1].size }[0..49]
    end
  end
  
  def self.top_tags_alph
    tags = Tag.top_tags
    alph_tags = tags.sort { |a,b| a[0] <=> b[0] }
    [alph_tags, tags[0][1].size, tags[-1][1].size] # [tags, most_opinions_per_tag, least_...]
  end
  
  def all_opinions
    tags = Tag.find(:all, :conditions => {:name => self.name} )
    opinions = []
    tags.each { |t| opinions << t.opinion }
    opinions
  end
  
end
