# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  #layout "standard", :except => [:ajax_method, :more_ajax, :another_ajax]
  
  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery #:secret => 'a09131009ea5875729d83c6ab4ad1ff1'
  #session :session_expires => 3.years.from_now
  #session :expire_after => 3.years.from_now

  ActionController::Base.session_options[:expire_after] = 2.years

  
  # See ActionController::Base for details 
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password"). 
  # filter_parameter_logging :password
  
  def notice(text, page='/', color='yellow')
    flash[:notice] = text
    flash[:color] = color
    flash.keep
    redirect_to page
#    @color = color
    
#    case page
#      when 'main_page'
#        redirect_to '/'
##        @opinions = Opinion.all(:order => 'id DESC')
##        render :template => 'misc/main_page'
#    end
  end
  
  private

  def create_user
    @user = User.create
    @user.login = @user.id.to_s  #(User.all[-1].id+1).to_s)
    @user.current_session_id = session.session_id
    @user.save
    session[:user] = @user
    #session[:oses] = []
    session[:new_user] = 0
  end

end
