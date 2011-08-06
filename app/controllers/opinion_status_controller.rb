#require_dependency "opinion_status.rb" # memcached vaatii tätä - similarsissa tallennetaan os:ia

class OpinionStatusController < ApplicationController
#  before_filter  :preload_models
# 
#  def preload_models()
#    OpinionStatus
#  end

  def modify_opinion
    create_user if session[:user].nil? and (params[:status]=='1' or params[:status]=='2') and request.method == :post
    
    render :text => "Virhe! Käyttäjän luonti epäonnistunut." and return if session[:user].nil?
    # render :nothing => true
    
    #os = OpinionStatus.find_or_create_by_user_id_and_opinion_id(:user_id => session[:user].id, :opinion_id => params[:opinion_id])
    op_open = false
    os = OpinionStatus.find_by_user_id_and_opinion_id(session[:user].id, params[:opinion_id])
    if os.nil?
      os = OpinionStatus.create(:user_id => session[:user].id, :opinion_id => params[:opinion_id], :status => params[:status], :anonymous => 1)
      session[:actions] << [os.status, os.opinion_id]
    else
      session[:actions].delete_if {|a| a[0]==os.status and a[1]==os.opinion_id }
      os.destroy
      op_open = true
    end
    #session[:oses] = session[:user].opinion_statuses
    os.opinion.update_op_stat_counters
    delete_cache(params[:opinion_id], session[:user].id)
    
    session[:new_user] += 1 if session[:new_user]
    
    # SEKALAISTA
#    oses = session[:oses].size
#    if oses==5 or oses==15 or oses==40 or oses==100
#      session[:user].similar_users(true) # <- tämä sen takia että luo uudestaan similarity prosentin kaikkien käyttäjien kanssa
#    end
    
    # SIVUN RENDERÖINTI:
    if !defined? os # tää voi tapahtuu vaan jos käyttäjän luonti on epäonnistunut
      @opinion = nil
    else
      @opinion = os.opinion
    end
    
#    @comments = Comments.find_by_opinion_id(@opinion.id)
#    session[:read_com][@opinion.id] = @comments.size
    
    render :partial => 'opinion/op_more', :locals => { :os_changed => true, :op_open => op_open }
  end

  def hide
    # os:sää ei pitäs olla olemassa, mutta myös find siltä varalta että ajax käyttöliittymä on sotkeutunut
    os = OpinionStatus.find_or_create_by_user_id_and_opinion_id(:user_id => session[:user].id, :opinion_id => params[:opinion_id], :status => 3, :anonymous => 1)
    session[:actions] << [os.status, os.opinion_id]
  end
  
#  def change_anonymity
#    if params[:type] == 'OpinionStatus'
#      item = OpinionStatus.find(params[:id])
#    elsif params[:type] == 'Opinion'
#      item = Opinion.find(params[:id])
#    else # params[:type] == 'Comment'
#      item = Comment.find(params[:id])
#    end
#    
#    if (params[:type] == 'Opinion' and item.creator == session[:user]) or item.user == session[:user]
#      item.update_attribute(:anonymous, !item.anonymous)
#    end
#  end
  
  private
  
  def delete_cache(op_id, user_id)
    
    Rails.cache.delete("site_stats")
    Rails.cache.delete("latest_opinions[#{op_id}]")
    Rails.cache.delete("opinion_salience[#{op_id}]")
    Rails.cache.delete("opinion_details[#{op_id}]")
      
    counter = Rails.cache.read("op_cache_counter[#{op_id}]")
    counter = counter.nil? ? 1 : counter + 1
    Rails.cache.write("op_cache_counter[#{op_id}]", counter)
    
    if counter%10 == 0
      Rails.cache.delete("similar_opinions[#{op_id}]")
      Rails.cache.delete("pos_correlations[#{op_id}]")
      Rails.cache.delete("neg_correlations[#{op_id}]")
      
      # peer percentages:
      User.all.each do |u|
        Rails.cache.delete("peer_percentages[#{u.id}-#{op_id}]")
      end
    end
    
    session[:counter] = session[:counter].nil? ? 1 : session[:counter]+1
    
    if session[:counter]%10 == 0
      #User similarities
      User.all.each do |u|
        ids = user_id < u.id ? "#{user_id}-#{u.id}" : "#{u.id}-#{user_id}"
        Rails.cache.delete("users_similarity[#{ids}]")
      end
      # similar users:
      Rails.cache.delete("similar_users[#{user_id}]") # muiden suhde tähän käyttäjään ei päivity, mut eipä tuolla niin väliks
    end
  end
end