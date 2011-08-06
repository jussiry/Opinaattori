class CommentController < ApplicationController

  def create_new
    create_user if session[:user].nil?
    
    unless params[:filter].blank?
      render :text => "kommenttisi jäi spämmi filtteriin" and return
    end
    opinion = Opinion.find(params[:comment][:opinion_id])
    if params[:comment][:text].blank?
      #render :text => params[:comment].inspect and return
      render :partial => "comments", :locals => {:opinion => opinion} and return
    end
    comment = Comment.new(params[:comment])
    comment.update_attribute(:user_id, session[:user].id)
    session[:actions] << [$act_comment, comment.opinion_id]
    render :partial => "comments", :locals => {:opinion => opinion, :new_com => true}
  end
  
  def comments
    #@comments = Comment.find_by_opinion_id(:opinion_id => params[:opinion_id], :conditions => {:reply_id => nil}, :order => "reverse")
#    if video = Video.find(params[:video_id])
#      render :partial => "comments", :locals => {:video => video}
#    else
#      render :text => "BUG: video not found!"
#    end
  end

  def new_comment_form
    #render :text => 'plaa'
    comment = Comment.find(params[:reply_to_id])
    render :partial => 'comment/new_comment_form', :locals => {:opinion => comment.opinion, :reply_id => params[:reply_to_id]}
  end
  
end
