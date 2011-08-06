class MainPageController < ApplicationController
  
  def action_log
    render :partial => '/main_page/action_log'
  end
  
  def insert_opinions
    first = session[:next_op]
    @new_opinions = session[:opinions][first..first+5]
    session[:next_op] += 6
    @opinions_left = session[:next_op] <= session[:opinions].length 
  end
  
  def main_page
    
    session[:read_com] = [] if session[:read_com].nil?
    
    
    #begin # häkki, joka korjaa sen että joillain on sessionssissa vanhoja opinioneja
    #  session[:opinions][0].comments_count
    #rescue
    #  session[:opinions] = nil
    #end
    redirect_to :action => 'opinions_all' if session[:opinions].nil?
    
    #checks_before_render_main_page
    #@opinions = Opinion.all(:order => 'id DESC')
  end

  # SIIRRÄ MISCISTÄ TÄNNE...
  
#  def reset_opinions
#    if session[:show].nil? or session[:show][:all]
#      redirect_to :action => 'opinions_all'
#    elsif session[:show][:tag]
#      redirect_to :action => 'opinions_by_tag'
#    else #session[:show][:new]
#      redirect_to :action => 'opinions_new'
#    end
#  end
  
  def opinions_all
    #session[:index] = 0
    session[:show] = { :all => true }
    session[:opinions] = Opinion.all
    session[:opinions] = [] if session[:opinions].nil?
    session[:opinions_text] = "<h2 class='round15'>Suositut</h2>"
    #remove_hidden(true) if session[:user]
    #session[:opinions_text] = "<div style='font-size:0.8em'>#{removed} vastattua mielipidettä piilotettu</div>" if removed and removed > 0
    session[:opinions].sort! { |a,b| b.salience <=> a.salience }

    redirect_to :action => 'main_page'
    
    # JOKU PÄIVÄ TÄN VOIS tehä niinkin et ois status_opinioneja oninionin sijaan; ois huomattavasti tehokkaampi, koska nyt status_opinonit pitää taas hakee erikseen viewissä
    # hmm.. tai siis eiks ois järkevin että on molempia?
  end

  def opinions_by_tag
#    render :text => Tag.tag_hash.inspect and return
    #session[:index] = 0
    session[:opinions] = []
    session[:show] = { :tag => params[:tag] } unless params[:tag].nil?
#    render :text => params[:tag] + Tag.tag_hash[params[:tag]].inspect
    unless Tag.tag_hash[session[:show][:tag]].nil? # tapahtuu lähinnä sillon jos uutta tagia ei oo vielä cachessa
      Tag.tag_hash[session[:show][:tag]].each do |op_id|
        op = Opinion.find_by_id(op_id)
        session[:opinions] << op unless op.nil? # jos tuhottu, mutta edelleen tag-cachessa
      end
    end
    #remove_hidden if session[:user]
    session[:opinions].sort! { |a,b| b.salience <=> a.salience }
    if session[:opinions].size > 0
      session[:opinions_text] = "<h3 class='round15'>#{session[:show][:tag].gsub(/_/, ' ').capitalize}</h3>"
    else
      session[:opinions_text] = "Ei yhtään mielipidettä tagilla <h3 class='round15'>#{session[:show][:tag].gsub(/_/, ' ').capitalize}</h3>."
    end
    #checks_before_render_main_page
    render :action => 'main_page'
  end
  
  def opinions_new
    #session[:index] = 0
    session[:show] = { :new => true }
    session[:opinions] = Opinion.all
    #remove_hidden if session[:user]
    session[:opinions_text] = "<h2 class='round15'>Uudet</h2>"
    session[:opinions].sort! { |a,b| b.created_at <=> a.created_at }
    redirect_to :action => 'main_page'
  end
  
  def opinions_answered
    session[:show] = { :answered => true }
    session[:opinions] = OpinionStatus.find(:all, :conditions => "user_id = #{session[:user].id} and (status=1 or status=2)").reverse.map {|os| os.opinion }
    session[:opinions_text] = "<h2 class='round15'>Vastatut</h2>"
    redirect_to :action => 'main_page'
  end
  
  # SIDEBAR PARTIALS:
  
  def user_menu
    render :partial => '/main_page/user_menu'
  end
  
  def tag_cloud
    render :partial => '/main_page/tag_cloud'
  end
  
  private
  
#  def remove_hidden(hide_answered=false)
#    removed = 0
#    session[:oses].each do |os|
#      if os.status == 3 # piilotettu
#        removed += 1 unless session[:opinions].delete(os.opinion).nil?
#      elsif hide_answered and (os.status == 1 or os.status == 2)
#        unless session[:opinions].delete(os.opinion).nil?
#          removed += 1
#        end
#      end
#    end
#    session[:op_hidden] = removed
#  end
  
#  def checks_before_render_main_page
#    if session[:opinions].nil?  or (Time.now-session[:opinions_updated]) > 1.hour
#      reset_opinions(false)
#      return 
#    end
#    session[:index] = 0 if session[:index].nil? # tämä ei normaalisti ole mahdollista - ainoastaan jos on vanha käyttäjä jolle :indexiä ei ole asetettu
#    session[:opinions_removed] = 0
#    session[:index] -= $op_per_page if session[:index] > session[:opinions].size
#    session[:index] = 0 if session[:index] < 0
#  end
  
  
end
