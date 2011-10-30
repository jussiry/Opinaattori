class UserController < ApplicationController
  
  def activity_log
    @user = User.find_by_login(params[:login])
    render :partial => '/user/activity_log'
  end
  
  def login_form
    render :partial => 'login'
  end

  def login
    if request.method == :post
      begin
        params[:user][:login].downcase!
        new_user = User.authenticate(params[:user][:login], params[:user][:password])
      rescue
        # miks tässä on ylipäätään begin/rescue rakenne?
      end
      if new_user.nil?
        notice "Väärä käyttäjätunnus tai salasana. Yritä uudelleen.", '/?login_form=true', 'red'
        #render :text=>"<p style='margin:0 3em; color:red'>User or password not found.</p>", :layout => true and return
      else
        
        # deletoidaan mahdollinen vanha sessio tietokannasta:
#        sessions = CGI::Session::ActiveRecordStore::Session.all
#        sessions.each do |s|
#          s.destroy if s.login == params[:login]
#        end
        
        if session[:user].nil?
          # destroy old session and update current session to user table
          unless new_user.current_session_id.nil?
            #old_session = CGI::Session::ActiveRecordStore::Session.find_by_session_id(new_user.current_session_id)
            old_session = ActiveRecord::SessionStore::Session.find_by_session_id(new_user.current_session_id)
            # copy stuff from old session before destoying it:
            unless old_session.nil?
              session[:read_com] = old_session.data[:read_com] unless old_session.data[:read_com].nil?
              old_session.destroy
            end
          end
          new_user.update_attribute(:current_session_id, session.session_id)
          
          session[:user] = new_user
          #session[:oses] = new_user.opinion_statuses
          notice "\"#{session[:user].login}\" loggautunut", '/', 'green'
        elsif session[:user] == new_user
          notice "Olet jos valmiiksi loggautuneena tällä tunnuksella.", '/', 'yellow'
        else
          text = combine_users(new_user)
          notice text, '/', 'green'
        end
      end
    end
  end
  
  def logout
    reset_session
    redirect_to '/' #:controller => 'user', :action => 'signup'
  end
  
#  def picture_small
#    user = User.find_by_login(params[:login])
#    send_data(user.image_small, :filename => "user_picture", :type => user.image_type, :disposition => "inline" )
#  end
  
  def show
    if (@user = User.find_by_login(params[:login])).nil?
      notice "Käyttäjää tunnuksella '#{params[:login]}' ei löytynyt.", '/', 'red' and return
    end
    #@wall = OpinionStatus.find_by_opinion_id_and_user_id(@user.wall_opinion_id, @user.id)
    #@wall = Opinion.find_by_id(@user.wall_opinion_id) if @wall.nil?
    @similarity, @max_similarity, @agree, @disagree = @user.similarity(session[:user]) unless session[:user].nil?
    @title = @user.name_or_login
  end
  
  
  def settings
    render :text => "Ei käyttäjätunnusta." and return if session[:user].nil?
    if request.method == :post
      if session[:user].login == params[:login]
        flash[:color] = 'red'
        flash[:notice] = ""
        # Login:
        params[:new_login].delete! "<>" if params[:new_login]
        params[:new_login].downcase! if params[:new_login]
        params[:user][:name].delete! "<>" if params[:user][:name]
        params[:user][:url].delete! "<>" if params[:user][:url]
        unless params[:new_login].blank?
          if !(params[:new_login] =~ /[A-z, Ä-ö]/)
            flash[:notice] << "Käyttäjä tunnuksessa täytyy olla kirjaimia!&nbsp; "
            #return
          elsif params[:new_login] != session[:user].login
            login_taken = User.find_by_login(params[:new_login])
            if login_taken.nil?
              session[:user].update_attribute(:login, params[:new_login])
            else
              flash[:notice] << "Käyttäjätunnus \"#{params[:new_login]}\" on varattu.&nbsp; "
              #return
            end
          end
        end
        # password:
        unless params[:password].blank? and params[:password2].blank?
          if params[:password] == params[:password2]
            session[:user].update_attribute(:password, params[:password])
          else
            flash[:notice] << "Salasanat eivät olleet yhtenevät!&nbsp; " # sal:#{params[:password]}-
            #return
          end
        end
        # user picture:
        unless params[:uploaded_picture].blank?
#          begin
            Picture.uploaded_user_picture(session[:user], params[:uploaded_picture])
#          rescue
#            flash[:notice] << "Kuvaformaatti ei kelpaa (todennäköisesti et valinnut kuvatiedostoa).&nbsp; "
#          end
        end
        
        
        session[:user] = User.update(session[:user].id, params[:user])
        
        session[:user].update_attribute(:sex, params[:sex]) # sex is set with select_tag and works differently
        session[:user].update_attribute(:birthdate, params[:birth_year]+"-01-01") unless params[:birth_year].blank?
        if flash[:notice].empty?
          flash[:color] = 'green'
          flash[:notice] = "Asetukset päivitetty!"
        else
          flash[:notice] << "Muut asetukset päivitetty."
        end
        if params[:login] != session[:user].login
          redirect_to :controller => 'user', :action => 'settings', :login => session[:user].login
        end
      end
    end
  end
  
  def put_on_wall
    session[:user].wall_opinion_id = params[:id]
    session[:user].save
    redirect_to :action => 'show', :login => session[:user].login
  end
  

  
  private
  
  def combine_users(new_user)
    # combine session[:user] to new_user
    session[:user].opinions.each do |o|
      o.update_attribute(:creator_id, new_user.id)
    end
    opinions_created = session[:user].opinions.size
    
    session[:user].opinion_statuses.each do |os|
      if sec_os = new_user.opinion_statuses.find_by_opinion_id(os.opinion.id) # :first,
        #render :text => "sec_os: #{sec_os.inspect}" and return
        sec_os.destroy
      end
      os.update_attribute(:user_id, new_user.id)
    end
    opinions_given = session[:user].opinion_statuses.size
    
    session[:new_user] = false # ettei näytä "uusi käyttäjä luotu" -tekstiä jos sitä ei ollut näytetty
    session[:user].destroy
    session[:user] = new_user
    return "#{opinions_created} luotua mielipidettä ja #{opinions_given} annettua mielipidettä liitetty käyttäjään \"#{session[:user].login}\""
  end
  
  
end
