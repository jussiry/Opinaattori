class OpinionStatus < ActiveRecord::Base
  belongs_to :opinion
  belongs_to :user
  validates_presence_of :user, :opinion
  
  def anonymous
    (read_attribute(:anonymous)==1 or read_attribute(:anonymous)==true) ? true : nil
  end
  
#  def destroy
#    case self.status
#      when 1
#        self.opinion.pos -= 1
#      when 2
#        self.opinion.neg -= 1
#      when 3
#        self.opinion.hid -= 1
#    end
#    super.destroy
#  end

#  def status=(value)
#    op = self.opinion
#    op.update_attribute(:pos, op.pos+1) if self.status != 1 and value == 1
#    op.neg += 1 if self.status != 2 and value == 2
#    op.pos -= 1 if self.status == 1 and value != 1
#    op.neg -= 1 if self.status == 2 and value != 2
#    self.status = value
#  end
  
  
end
