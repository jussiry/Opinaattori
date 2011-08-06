module MiscHelper
  def site_stats
    User
    Rails.cache.fetch("site_stats") do
      name = no_name = 0
      User.all.each do |u|
        if u.has_login?
          name += 1
        else
          no_name += 1
       end
      end
      op_stat = OpinionStatus.find(:all, :conditions => "status = 1 OR status = 2")
      { :with_name => name, :without_name => no_name, :opinions => Opinion.all.size,
        :opinion_statuses => op_stat.size, :comments => Comment.all.size }
     end
  end
end
