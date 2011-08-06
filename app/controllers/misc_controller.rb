class MiscController < ApplicationController
  
  def debug  
  end
  
  def test
    str = ""
    Opinion.find(83).comments.each do |c|
      c.destroy
    end
    render :text => "jep"
  end
  
  
  def picture
    pic = Picture.find(params[:id])
    send_data(pic.picture_data, :filename => "user_picture", :type => pic.picture_type, :disposition => "inline" )
  end
  
#  def eval
#    #reder :text => "no access" and return if cur_user.nil? or cur_user.login != 'jussir'
#    logger.debug eval(params[:command])
#    render :text => "plaa"
#  end
  
#  def picture
#    user = User.find_by_login(params[:login])
#    pic = user.picture
#    send_data(pic, :filename => "user_picture", :type => pic.image_type, :disposition => "inline" )
#  end
#  
#  def picture_large
#    user = User.find_by_login(params[:login])
#    pic = user.large_picture
#    send_data(user.image_large, :filename => "user_picture", :type => user.image_type, :disposition => "inline" )
#  end
  
  def show_current_user
    redirect_to :controller => 'user', :action => 'show', :login => session[:user].login
  end
  
  def show_current_user_settings
    redirect_to :controller => 'user', :action => 'settings', :login => session[:user].login
  end
  
  def anonym_mode
    session[:anonymous] = session[:anonymous] ? nil : true
    render :partial => 'misc/anonym_mode'
  end
  
  def search
    if params[:search].blank?
      session[:opinions_text] = "<div style='color:red'>Hakulauseesi oli tyhjä!</div>"
      redirect_to :action => "main_page" and return
    end
    session[:show] = { :search => true }
    results = Opinion.search params[:search], :case => :sensitive
    if results.size > 0
      session[:opinions] = results
      session[:index] = 0
      session[:opinions_text] = "<h3 class='round15'>\"#{params[:search]}\"</h3>"
    else
      session[:opinions_text] = "<div style='color:red'>Haulla \"<strong>#{params[:search]}</strong>\" ei löytynyt tuloksia.</div><div>Ehkä haluaisit tehdä aiheesta uuden mielipiteen?</div>"
      session[:opinions] = []
    end
    flash[:searchwords] = params[:search]
    redirect_to :controller => 'main_page', :action => "main_page"
#    render :text => Opinion.all.inspect #params[:search].inspect
  end
  
  def info
    
  end
  
  def new_feedback
    Feedback.create(:user_id => (session[:user] ? session[:user].id : nil), :text => params[:feedback_text])
    render :text => "<div style='font-weight:bold;color:green;'>Kiitos palautteestasi!</div><div>Mikäli laitoit palautteen mukaan sähköpostiosoitteesi, vastaamme siihen mahdollisimman pian.</div><br/>"
  end
  
  def rss_new_opinions
    @items = Opinion.find(:all, :order => 'created_at DESC', :limit => 30)
    @rss_title = "Opinaattori - uusimmat mielipiteet"
    render :template => '/misc/rss.xml', :layout => false
  end
  

  # MAINTENANCE
  
  def check_op_statuses
    OpinionStatus.all.each do |os|
      if os.user.nil? or os.opinion.nil?
        render :text => os.inspect and return
      end
    end
  end
  
  def update_op_stats
    Opinion.find(:all).each do |o|
      o.update_op_stat_counters
    end
    render :text => "done"
  end
  
  def empty_opinions_in_sessions
    sessions = ActiveRecord::SessionStore::Session.all
    User; OpinionStatus; Opinion; Comment; Tag
    sessions.each do |s|
      s.data[:opinions] = nil
      s.save
    end
    render :text => "done"
  end
  
  def init_comments_count
    Opinion.find(:all).each do |o|
      o.update_attribute(:comments_count, 0)
    end
    render :text => "done"
  end
  
  def reset_comments_count
    Opinion.find(:all).each do |o|
      Opinion.update_counters o.id, :comments_count => o.comments.count # kasvattaa counttien määrää, joten eka pitää ajaa init_comments_count
    end
    render :text => "done"
  end
  
  def inspect_sessions
    render :text => "no access" and return unless session[:user].login == "jussir"
    #User OpinionStatus Opinion

    @sessions = ActiveRecord::SessionStore::Session.all
  end
  
  
  def destroy_empty_sessions
    render :text => "no access" and return unless session[:user].login == "jussir"
    #User OpinionStatus Opinion
    sessions = ActiveRecord::SessionStore::Session.all(:limit => 2500) 
    i = 0
    sessions.each do |s|
      if s.data[:user].nil?
        s.destroy
        i += 1
      end
    end
    render :text => "done. destroyed #{i} sessions"
  end
    
  def cache
    html = Rails.cache.inspect
    html << "<br/> active: #{Rails.cache.data.active?}"
    render :text => html # MemCache.inspect
  end
  
  def cache_test
    time = Rails.cache.fetch("cache_test", :expires_in => 10.seconds) do
      Time.now
    end
    render :text => "aika: #{time.strftime('%H:%M:%S')}"
  end
  
  def empty_cache
    Rails.cache.clear
    render :text => "done"
  end
  
  def destroy_empty_users
    users = User.all
    users.each do |u|
      next if u.comments.size > 0 or u.opinions.size > 0
      destroy_user = true
      u.opinion_statuses.each do |os|
        if os.status == 1 or os.status == 2
          destroy_user = false
          break
        end
      end
      u.destroy if destroy_user
    end
    redirect_to :action => 'destroy_empty_opinion_statuses'
    #render :text => "done"
  end
  
  def destroy_empty_opinion_statuses
    oses = OpinionStatus.all
    oses.each do |os|
      os.destroy if os.user.nil?
    end
    render :text => "done"
  end

  
end
