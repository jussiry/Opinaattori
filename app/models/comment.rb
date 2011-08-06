class Comment < ActiveRecord::Base
  
  has_many :replies, :class_name => "Comment", :foreign_key => "reply_id"
  belongs_to :user
  belongs_to :opinion, :counter_cache => true
  belongs_to :reply_to, :class_name => "Comment", :foreign_key => "reply_id"
  
  validates_presence_of :user, :opinion
  
  def anonymous
    (read_attribute(:anonymous)==1 or read_attribute(:anonymous)==true) ? true : false
  end
  
  def text
    read_attribute(:text).mb_chars
  end
  
#  def text_no_html
#    txt = self.text
#    txt.gsub!(/[",*,_]/, '')
#    while first = txt =~ /:http:\/\//
#      last = txt[first..-1] =~ /\s/
#      ending = last.nil? ? "" : txt[first+last..-1]
#      txt = txt[0..first-1] + ending
#    end
#    txt
#  end
  
#  def text_html
#    rtext = RedCloth.new self.text
#    rtext.to_html.gsub(/<p>/, '').gsub(/<\/p>/, '')
#  end
  
end
