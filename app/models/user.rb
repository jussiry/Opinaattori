
class User < ActiveRecord::Base
#  validates_presence_of :login
#  validates_uniqueness_of :login, :message => "Käyttäjätunnus on varattu."
  
  has_many :tags
  has_many :comments
  has_many :opinions, :class_name => "Opinion", :foreign_key => :creator_id # creator_id:kautta, en tiiä toimiiko näin
  has_many :opinion_statuses
  
  belongs_to :picture
  belongs_to :small_picture, :class_name => "Picture"
  belongs_to :op_picture, :class_name => "Picture"
  belongs_to :large_picture, :class_name => "Picture"
  
  #cache = ActiveSupport::Cache.lookup_store(:memory_store)  #(:mem_cache_store)
  
  def self.authenticate(login, password)
    find(:first, :conditions => ["login = ? and password = ?", login, Digest::SHA1.hexdigest(password)])
    #user =  #return user.nil? ? false : user
  end
  
  def password=(value)
    write_attribute("password", Digest::SHA1.hexdigest(value)) unless value.blank?
  end
  
  def login_or_new
    return login if has_login?
    #return (Time.now-created_at) > 1.day ? "nimetön#{self.id}" : "uusi käyttäjä"
    return "nimetön#{self.id}"
  end
  
  def name_or_login
    self.name.blank? ? self.login_or_new : self.name
  end
  
  def has_login?
    login =~ /[A-z, Ä-ö]/ ? true : false
  end
  
  def similarity(user2) #, delete_cache=false
    user1 = self
#    if user1 == user2
#      # itsen kohdalla palauta maksimi
#      oses = OpinionStatus.find(:all, :conditions => "user_id = #{self.id} AND (status = 1 OR status = 2)")
#      max = oses.size == 0 ? 0 : ((1.0-Math.sqrt(1.0/oses.size))*100).to_i
#      return [max, max, oses.size, 0]
#    end
    ids = user1.id < user2.id ? "#{user1.id}-#{user2.id}" : "#{user2.id}-#{user1.id}"
#    smaller_ops_size = (ops1 = user1.opinion_statuses.size) < (ops2 = user2.opinion_statuses.size) ? ops1 : ops2
#    if smaller_ops_size < 15
#      exp = 5.minutes
#    elsif smaller_ops_size < 100
#      exp = 1.hour
#    else
#      exp = 24.hours
#    end
    
#    Rails.cache.delete("users_similarity[#{ids}]") if delete_cache
    
    Rails.cache.fetch("users_similarity[#{ids}]") do # , :expires_in => 12.hours
      user1_os = OpinionStatus.find(:all, :conditions => "user_id = #{user1.id} AND (status = 1 OR status = 2)") # .find_all_by_user_id(user1.id)  #
      user2_os = OpinionStatus.find(:all, :conditions => "user_id = #{user2.id} AND (status = 1 OR status = 2)") # .find_all_by_user_id(user2.id)
      disagree = agree = 0.0
      user1_os.each do |os1|
        user2_os.each do |os2|
          if os1.opinion_id == os2.opinion_id
            if os1.status == os2.status
              agree += 1
            else
              disagree += 1
            end
            break
          end
        end
      end
      #@agree = 30.0; @disagree = 1.0
      
      #yht/kaik * (1 - sqr(1/kaik))
      common = agree + disagree
      if common == 0
        [0,0,0,0]
      else
        max_similarity =  1.0 - Math.sqrt(1/common) # muista päivittää myös ylös silloin kun on itsestä kyse
        similarity = (agree / common) * max_similarity
        max_similarity = (max_similarity*100).to_i
        similarity = (similarity*100).to_i
        [similarity, max_similarity, agree, disagree]
      end
    end # end fetch
  end # end similarity function
  
  def similar_users() #delete_cache=false
    User
#    if delete_cache or ($users_chanched and $users_chanched.include?(self.id))
#      Rails.cache.delete("similar_users[#{self.id}]")
#      $users_chanched.delete self.id
#    end
    
    Rails.cache.fetch("similar_users[#{self.id}]", :expires_in => 20.hours) do
      users = User.all
      users_and_sim = []
      users.each do |u|
        next if u == self
        next unless u.has_login?
        
#       sim = similarity(u)
#       sim = sim.nil? ? 0 : sim
        users_and_sim << [u, similarity(u)[0], similarity(u)[1]] # (u, true)
      end
      users_and_sim
      users_and_sim.sort! { |a,b| b[1] <=> a[1] }
      users_and_sim[0..6]
    end
  end
    
end
