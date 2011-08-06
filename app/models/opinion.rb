#require 'redcloth'
require_dependency "search"
require_dependency "opinion_status.rb" # memcached vaatii tätä - similarsissa tallennetaan os:ia

class Opinion < ActiveRecord::Base
  belongs_to  :creator,
              :class_name => "User",
              :foreign_key => "creator_id"
  has_many :tags
  has_many :opinion_statuses
  has_many :comments
  
  searches_on :all
  
#  def before_update
#    begin
#      @run_updates = ((Time.now.to_i-self.updated_at.to_i) > 3) # tää estää recordin tallentamisen
#    rescue
#    end
#    @run_updates = "lallallaa" # tää ei.. vidu hämärää
##    jaa = "poaa"
#  end
  
#  def after_update
#    #update_salience if @run_updates
#  end
  
  def text
    read_attribute(:text).mb_chars # .mb_chars käsittelee multibytenä (UTF-8)
  end
  
  def text_no_html
    Markup.no_html(text)
  end
  
#  def text_html
#    rtext = RedCloth.new self.text
#    rtext.to_html.gsub(/<p>/, '').gsub(/<\/p>/, '')
#  end
  
  def anonymous
    (read_attribute(:anonymous)==1 or read_attribute(:anonymous)==true) ? true : false
  end
  
  def percentage_all
    self.pos + self.neg == 0 ? "0%" : (self.pos*100 / (self.pos+self.neg)).to_s + "%"
  end
  
  def percentage_all_num
    self.pos + self.neg == 0 ? 0 : (self.pos*100 / (self.pos+self.neg))
  end
  
  def percentage_neg_all
    self.pos + self.neg == 0 ? "0%" : (100-percentage_all_num).to_s + "%"
  end
  
  def answers
    pos + neg
  end
  
  def update_op_stat_counters
    self.pos = self.neg = self.hidden = 0 # = self.hid = 0
    self.opinion_statuses.each do |os|
      if os.status == 1
        self.pos += 1
      elsif os.status == 2
        self.neg += 1
      elsif os.status == 3
        self.hidden += 1
      end
    end
    #update_salience # tää oli aiemmin before_updatessa, mut se sotki recordin tallentumista sika hämärästi
    self.save
  end
  
  def cached_tags
    Tag   # memcahcea varten
    Rails.cache.fetch("opinion_tags[#{self.id}]") do
      tag_array = [] # [ [tag, count] ... ]
      self.tags.each do |t|
        already_added = false
        tag_array.each do |added_tag|
          if t.name == added_tag[0].name
            added_tag[1] += 1
            already_added = true
            break
          end
        end
        tag_array << [t, 1] unless already_added
      end
      tag_array.sort { |a,b| b[1] <=> a[1] }
    end
  end
  
  def salience
#    age = Time.now-self.created_at
#    expires = 5.minutes if age < 1.hour
#    expires = 1.hour if age < 1.day
#    expires = 1.day if age > 1.day
    
    # MEMCACHE HACK
#    Rails.cache.delete("opinion_salience[#{self.id}]")
    
    Rails.cache.fetch("opinion_salience[#{self.id}]") do # , :expires_in => expires
      age = Time.now - created_at
      # alle kahden päivän ikäsille iso bonus (jopa 25 kertainen)
      if age < (short_time = 2.days)
        age_multip = 33 * (short_time - age) / short_time
      else
        age_multip = 1
      end
      # mutta myös alle kuukauden ikäsille pienempi bonus:
      if age < (longer_time = 20.days)
        age_multip += 10 * (longer_time - age) / longer_time
      end
      
      comment_bonus = self.comments.size*3
      opinion_bonus = 2*self.pos + self.neg #self.opinion_statuses(:all, :conditions => "status == 1 OR status == 2").size
      hide_minus = 2*OpinionStatus.find(:all, :conditions => "opinion_id = #{self.id} AND status = 3").size
      # tässä vois myös miinustaa hidden countit, mut hidastas kun pitäs ladata opinion statukset
      (age_multip * (1 + comment_bonus + opinion_bonus - hide_minus)).to_i # +1, so that the result can't be 0
    end
  end
  
  def details
    men_pos = men_neg = women_pos = women_neg = sex_unknown = 0
    under_25_pos = under_25_neg = under_50_pos = under_50_neg = older_pos = older_neg = age_unknown = 0
    all = anonym = 0
    
    Rails.cache.fetch("opinion_details[#{self.id}]") do
      self.opinion_statuses.each do |os|
        next unless os.status == 1 or os.status == 2
        if os.user.sex.blank?
          sex_unknown += 1
        elsif os.user.sex == 1
          men_pos += 1 if os.status == 1
          men_neg += 1 if os.status == 2
        elsif os.user.sex == 2
          women_pos += 1 if os.status == 1
          women_neg += 1 if os.status == 2
        end
        
        if os.user.birthdate.blank?
          age_unknown += 1
        else
          age = ((Date.today - os.user.birthdate)/365).to_i
          if age < 25
            under_25_pos += 1 if os.status == 1
            under_25_neg += 1 if os.status == 2
          elsif age < 50
            under_50_pos += 1 if os.status == 1
            under_50_neg += 1 if os.status == 2
          else
            older_pos += 1 if os.status == 1
            older_neg += 1 if os.status == 2
          end
        end
        anonym += 1 if os.anonymous
        all += 1
      end
      { :sex_unknown => sex_unknown, :men_percentage => (men_pos==0 ? 0 : (100*men_pos / (men_pos+men_neg))), :men_pos => men_pos, :men_neg => men_neg, :men_comb => (men_pos+men_neg),
      :women_percentage => (women_pos==0 ? 0 : (100*women_pos / (women_pos+men_neg))), :women_pos => women_pos, :women_neg => women_neg, :women_comb => (women_pos+women_neg),
      :age_unknown => age_unknown, :age_under_25_per => (under_25_pos == 0 ? 0 : (100*under_25_pos / (under_25_pos+under_25_neg))), :age_under_25_pos => under_25_pos, :age_under_25_neg => under_25_neg, :age_under_25_comb => (under_25_pos+under_25_neg),
      :age_under_50_per => (under_50_pos == 0 ? 0 : (100*under_50_pos / (under_50_pos+under_50_neg))), :age_under_50_pos => under_50_pos, :age_under_50_neg => under_50_neg, :age_under_50_comb => (under_50_pos+under_50_neg),
      :age_older_per => (older_pos == 0 ? 0 : (100*older_pos / (older_pos+older_neg))), :age_older_pos => older_pos, :age_older_neg => older_neg, :age_older_comb => (older_pos+older_neg),
      :anonymous => anonym, :anonymous_per => all > 0 ? (100*anonym / all) : 0 }
    end
  end
  
  def similar_opinions
    OpinionStatus # so that memcahced can use OpinionStatus
    Tag
    User
    
#    Rails.cache.delete("similar_opinions[#{self.id}]")

    Rails.cache.fetch("similar_opinions[#{self.id}]") do # , :expires_in => 1.day
      similars = [] # [ [opinion, count], ... ]
      #op_statuses = OpinionStatus.find_all_by_id(self.id, :conditions => "status == 1 OR status == 2")
      
      self.opinion_statuses.each do |os| # OpinionStatus.find_all_by_user_id(self.id) 
        next unless (os.status == 1 or os.status == 2)
        # käy läpi kaikki annetut mielipiteet ja anta niiden käyttäjien
        # antamiin muihin mielipiteisiin plussan, joissa ovat samaa mieltä kuin tässä
        os.user.opinion_statuses.each do |os2|  # .find(:all, :conditions => "status == 1 OR status == 2")
          next unless (os2.status == 1 or os2.status == 2)
          next if os2.opinion == self
          added_already = false
          addon = (os.status == os2.status ? 2 : 1)
          similars.each do |sim|
            if sim[0].id == os2.opinion_id
              sim[1] += addon
              added_already = true
              break
            end
          end
          similars << [os2.opinion, addon] unless added_already
        end
      end
      # tags:
      self.tags.each do |t|     # ct = [tag, tag_count]
        t.all_opinions.each do |o|
          next if o == self
          added_already = false
          similars.each do |sim|
            if sim[0] == o
              sim[1] += 6
              added_already = true
              break
            end
          end
          similars << [o, 6] unless added_already
        end
      end
      # tähän haku hommeli:
      words = self.text.split
      words.each do |w|
        w.downcase!
        next if w=='ei' or w=='ja' or w=='on'
        found = Opinion.search w, :case => :sensitive # oikeesti ei välitä case:sta
        found.each do |o|
          next if o == self
          added_already = false
          similars.each do |sim|
            if sim[0] == o
              sim[1] += 10
              added_already = true
              break
            end
          end
          similars << [o, 10] unless added_already
        end
      end
      
      similars.sort! { |a,b| b[1] <=> a[1] }      
      #similars[0..6]

#      [[Opinion.new(:text => 'aa'), 1, OpinionStatus.new(:user => User.new(:login=>"kakka"))], [Opinion.new(:text => 'bb'), 2]]
    end # end of fetch
  end # end of similars -function
  
  def latest_opinions
    Rails.cache.fetch("latest_opinions[#{self.id}]") do
      oses = self.opinion_statuses.all(:conditions => "status = 1 OR status = 2").reverse
      final_oses = []
      oses.each do |os|
        final_oses << os if !os.anonymous and os.user.has_login?
        break if final_oses.size == 4
      end
      final_oses
    end
  end
    
#  def self.all_pos_correlations(opinion_id)
#    pos_correlations(opinion_id)
#    Rails.cache.read("all_pos_correlations[#{opinion_id}]")
#  end
  
  def self.pos_correlations(opinion_id)
    User
    OpinionStatus
#    Rails.cache.delete("pos_correlations[#{opinion_id}]")
    Rails.cache.fetch("pos_correlations[#{opinion_id}]") do
      # POSITIVE CORRELATIONS:
      pos_opinions = {}
      poses = OpinionStatus.find(:all, :conditions => "opinion_id = #{opinion_id} AND status = 1")
      poses.each do |os|
        os.user.opinion_statuses.each do |os2|
          next if (os2.status != 1 and os2.status != 2) or os2 == os
          if pos_opinions[os2.opinion_id].nil?
            pos_opinions[os2.opinion_id] = [(os2.status == 1 ? 1 : 0)]
          else
            pos_opinions[os2.opinion_id] << (os2.status == 1 ? 1 : 0)
          end
        end
      end
      pos_opinions = pos_opinions.to_a
      # pos_opinions = [ [op_id, [1,1,0,0]], ... ]
      
      pos_opinions.each do |opid_values|
        opinion = Opinion.find(opid_values[0])
        opid_values[0] = opinion
        sum = 0; opid_values[1].each { |v| sum += v }
#        per = sum*100/opid_values[1].size
#        diff = per-opinion.percentage_all_num
        # effect = dif * answers:
        # 50 rajoitus, koska tällöin oletetaan, että vastauksen prosenttiluku ei enää muutu lisävastauksilla
        effect = ((sum > 50 ? 50 : sum) * 100) - (opinion.percentage_all_num * opid_values[1].size)
        # [percentage, per_change, total, effect, orig_per]:
        #opid_values[1] = [per, diff, opid_values[1].size, diff*opid_values[1].size, opinion.percentage_all_num]
        opid_values[1] = [sum, opid_values[1].size, opinion.percentage_all_num, effect]
      end
      # pos_opinions = [ [opinion, [per,per_change,tot,value]], ... ]
      pos_opinions.sort! { |a,b| b[1][3].abs <=> a[1][3].abs }
#      pos_opinions = pos_opinions[0..100] # 50
#      Rails.cache.write("all_pos_correlations[#{opinion_id}]", pos_opinions.clone)
      #pos_opinions.delete_if { |po| po[1][3] < 160 } # MIN ANSWERS: 10 
      # lopuksi järjestetään niin että eniten muutosta sisältävät ylimmäs:
#      pos_opinions[0..6]
    end
  end
  
  def self.neg_correlations(opinion_id)
    User
    OpinionStatus
    #Rails.cache.delete("neg_correlations[#{opinion_id}]")
    Rails.cache.fetch("neg_correlations[#{opinion_id}]") do
      # POSITIVE CORRELATIONS:
      neg_opinions = {}
      neg_oses = OpinionStatus.find(:all, :conditions => "opinion_id = #{opinion_id} AND status = 2")
      neg_oses.each do |os|
        os.user.opinion_statuses.each do |os2|
          next if (os2.status != 1 and os2.status != 2) or os2 == os
          if neg_opinions[os2.opinion_id].nil?
            neg_opinions[os2.opinion_id] = [(os2.status == 1 ? 1 : 0)]
          else
            neg_opinions[os2.opinion_id] << (os2.status == 1 ? 1 : 0)
          end
        end
      end
      neg_opinions = neg_opinions.to_a
      # neg_opinions = [ [op_id, [1,1,0,0]], ... ]
      
      neg_opinions.each do |opid_values|
        opinion = Opinion.find(opid_values[0])
        opid_values[0] = opinion
        sum = 0; opid_values[1].each { |v| sum += v }
#        per = sum*100/opid_values[1].size
#        diff = per-opinion.percentage_all_num
        effect = ((sum > 50 ? 50 : sum) * 100) - (opinion.percentage_all_num * opid_values[1].size)
        # [percentage, per_change, total, effect, orig_per]:
        # opid_values[1] = [per, diff, opid_values[1].size, diff*opid_values[1].size, opinion.percentage_all_num]
        opid_values[1] = [sum, opid_values[1].size, opinion.percentage_all_num, effect]
      end
      # neg_opinions = [ [opinion, [per,per_change,tot]], ... ]
      neg_opinions.sort! { |a,b| b[1][3].abs <=> a[1][3].abs }
#      neg_opinions = neg_opinions[0..100] # 50
#      Rails.cache.write("all_neg_correlations[#{opinion_id}]", neg_opinions.clone)
      # lopuksi järjestetään niin että eniten muutosta sisältävät ylimmäs:
      #neg_opinions.delete_if { |po| po[1][2]<10 } # MIN ANSWERS: 10 
     # neg_opinions.sort! { |a,b| b[1][1].abs <=> a[1][1].abs }
#      neg_opinions[0..6]
    end
  end
  
end
