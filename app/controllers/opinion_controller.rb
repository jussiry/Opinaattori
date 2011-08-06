class OpinionController < ApplicationController
  
  def create
    create_user if session[:user].nil?
    
    params[:opinion_text].strip!
    
    if params[:opinion_text].empty? or params[:opinion_text] == "Kirjoita mielipiteesi tänne..."
      render :text => ""
    else
      txt = params[:opinion_text].strip
      txt = txt[0..0].upcase + txt[1..-1]
      txt << "." if txt.mb_chars[-1..-1] =~ /[A-z, Ä-ö]/
      anon = params[:op_anonym_input] ? true : false
      @opinion = Opinion.create(:text => txt, :creator_id => session[:user].id, :anonymous => anon, :comments_count => 0)
      @opinion.update_op_stat_counters
      session[:actions] << [$act_new_op, @opinion.id]
#      flash[:notice] = "Uusi mielipide luotu! Lisäämällä tageja helpotat sen löytymistä."
#      flash[:color] = "green"
      render :partial => 'opinion/opinion', :locals => { :opinion => @opinion, :op_open => true }
    end
  end
  
  def add_tag
    unless params[:tags].nil? or params[:opinion_id].nil?
      create_user if session[:user].nil?
      new_tags = params[:tags].split(",")
      #user_tags = session[:user].tags.collect! {|t| [t.name, t.}
      new_tag = false
      new_tags.each do |t|
        t.strip!
        t.downcase!
        t.gsub!(/ /,'_')
        t.gsub!(/[<,>,\/,=,",']/, '')
        exists = Tag.find_by_opinion_id_and_user_id_and_name(params[:opinion_id], session[:user].id, t)
        if exists.nil?
          Tag.create(:name => t, :opinion_id => params[:opinion_id], :user_id => session[:user].id)
          new_tag = true
        else
          notice("Olet jo lisännyt tämä tagin.", "/opinion/show/"+params[:opinion_id]) and return
        end
      end
      if new_tag
        Rails.cache.delete("opinion_tags[#{params[:opinion_id]}]")
        Rails.cache.delete("similar_opinions[#{params[:opinion_id]}]") # tagit vaikuttaa tähän
        Rails.cache.delete("tag_hash")
        Rails.cache.delete("top_tags")
      end
      #render :text => user_tags.inspect and return
    end
    @opinion = Opinion.find(params[:opinion_id])
    render :partial => "/opinion/tags"
  end
  
  def show
    #redirect_to '/'
    
    # init page params:
    #session[:read_com] = [] if session[:read_com].nil?
    
    begin
      @opinion = Opinion.find(params[:id])
      # .find(:id) antaa virheen jos ei löydy - vois käyttää myös .first(:id=>id), joka palauttaa nil, jos ei löydy
    rescue
      notice "Mielipidettä id:llä '#{params[:id]}' ei löytynyt.", '/', 'red' and return
    end
    @title = @opinion.text
    @comments = Comment.find_all_by_opinion_id(@opinion.id) # commentsia ei käytetä missään muualla...
    session[:read_com][@opinion.id] = @comments.size
    
    # ::::TÄN VOIS TEHÄ JO SIMILAR OPINIONSISSA:::: ois nopeempi kun ois cachessa
    # samankaltaiset tagien mukaan:
#    @sim_by_tags = {} # :tag_name => [tag_name, sim[op,str], sim[op,str], ...]
#    without_tags = ["ilman tagia", []] # @sim_by_tags[:without_tags]
#    @opinion.similar_opinions.each do |sim|
#      if sim[0].cached_tags.length == 0
#        without_tags[1] << sim # @sim_by_tags[:without_tags]
#      else
#        tag = sim[0].cached_tags[0][0] # [sims][tag,similarity]
#        @sim_by_tags[tag.name] = [] if @sim_by_tags[tag.name].nil?
#        @sim_by_tags[tag.name] << sim
#      end
#    end
#    @sim_by_tags = @sim_by_tags.sort { |a, b| b[1][0][1] <=> a[1][0][1] } #muuttaa arrayks; [ tagin_nimi, [ [tagi, *samankaltaisuus*], ... ] ]
#    @sim_by_tags << without_tags unless without_tags[1].length == 0
  end
  
  def op_more
    @opinion = Opinion.find(params[:op_id])
#    @comments = Comments.find_by_opinion_id(@opinion.id)
#    session[:read_com][@opinion.id] = @comments.size
    render :partial => '/opinion/op_more'
  end
  
  def correlations
    #@opinion_id = params[:id] # = Opinion.find(params[:id])
    render :partial => '/opinion/correlations', :locals => { :opinion_id =>  params[:id] }
  end
  
  def corr_box
    render :partial => '/opinion/corr_box', :locals => { :opinion_id =>  params[:id] }, :layout => false
  end
  
  def show_with_results
    opinion = Opinion.find(params[:id])
    render :partial => '/opinion/opinion', :locals => {:opinion => opinion, :with_div => false, :show_results => true}
  end
  
  def edit
    opinion = Opinion.find(params[:id])
    
    if params[:text].nil?
      render :partial => '/opinion/edit', :locals => {:opinion => opinion}
    else
      # lähetys; tallennetaan mielipide
      if (session[:user] == opinion.creator and (Time.now-opinion.created_at) < 30.minutes) or session[:user].login == "jussir"
        opinion.update_attribute(:text, params[:text])
        flash[:notice] = "Mielipidettä muokattu."
        flash[:color] = "green"
      else
        flash[:notice] = "Mielipiteen muokkaus mahdolisuus sulkeutunut."
        flash[:color] = "red"
      end
      redirect_to :action => 'show', :params => {:id => opinion.id}
    end
  end
  
  def destroy
    opinion = Opinion.find(params[:id])
    if (session[:user] == opinion.creator and (Time.now-opinion.created_at) < 30.minutes) or session[:user].login == "jussir"
      opinion.opinion_statuses.each do |os|
        os.destroy
      end
      opinion.comments.each do |c|
        c.destroy
      end
      opinion.tags.each do |t|
        t.destroy
      end
      Rails.cache.delete("opinion_tags[#{opinion.id}]")
      session[:opinions].delete(opinion)
      opinion.destroy
      flash[:notice] = "jada jada"
      #notice "Mielipidettä id:llä ei löytynyt.", '/user/henkilo67', 'red' and return
      notice("Mielipide poistettu.", "/", "green") and return
    else
      flash[:notice] = "Mielipiteen muokkaus mahdolisuus sulkeutunut."
      flash[:color] = "red"
      redirect_to :action => 'show', :params => {:id => opinion.id}
    end
  end
  
end
