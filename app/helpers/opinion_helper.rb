module OpinionHelper
  
  def chart(pos, neg, title='')
    pos_per = pos+neg == 0 ? 50 : 100*pos / (pos+neg)
    neg_per = 100 - pos_per
    size = 90
    #chtt=title  #  - #{pos}   - #{neg}
    # selityksillä: "<img src='http://chart.apis.google.com/chart?chco=33ff33,ff3333&chf=bg,s,ffffaa&chdl=#{pos_per} %|#{neg_per} %&cht=p&chs=130x80&chd=t:#{pos_per},#{neg_per}' />"
    "<img class='chart_img' src='http://chart.apis.google.com/chart?chco=ff9b70,a5fb6a&chf=bg,s,fefec8&cht=p&chs=#{size}x#{size}&chd=t:#{neg_per},#{pos_per}'
          style='width:#{size}px;height:#{size}px;'/>"
  end
  
  def visualize_peers(value, exact, tag)
    html = ''
    adj = value.abs == 3 ? 'huomattavasti ' : (value.abs == 1 ? 'hieman ' : '')
    title = "Vertaisjokkosi on #{adj}#{value<0?'vähemmän ':'enemmän '}samaa mieltä mielipiteestä. Tarkka arvo: #{exact}." # (tarkka arvo: #{exact})
    if value < 0
      html << "<#{tag} style='color:#d20;display:inline;' title='#{title}'>"
      value.abs.times { html << "-" }
      html << "</#{tag}>"
    elsif value == 0
      html << "<#{tag} title='Vertaisjoukkosi on samaa mieltä keskivertokäyttäjän kanssa. Tämä voi johtua myös vähäisistä vastausten määrästä. Tarkka arvo: #{exact}.'>=</#{tag}>"
    else
      html << "<#{tag} style='color:#080;display:inline;' title='#{title}'>"
      value.abs.times { html << "+" }
      html << "</#{tag}>"
    end
    html
  end
  
  def old_peers(opinion)
    #jaa, paa = session[:user].similarity(opinion.creator)
    
    if session[:user].nil?
      [-1, 0]
    else
      Opinion
      OpinionStatus
      id = "#{session[:user].id}-#{opinion.id}"
      
#      if $users_chanched and $users_chanched.include?(session[:user].id)
#        session[:user].similar_users(true)
#      end
      
    
      # MEMCAHCE HACK
      #Rails.cache.delete("peer_percentages[#{id}]")
      
      # myöhemmin cachen pituutta vois säätää niin, että lyhyempi jos vasta rekisteröitynyt (=vähän mielipiteitä)
      Rails.cache.fetch("peer_percentages[#{id}]") do # , :expires_in => 10.minutes
        positives = negatives = 0
        pos_opinion_statuses = OpinionStatus.find(:all, :conditions => "opinion_id = #{opinion.id} AND status = 1")
        pos_opinion_statuses.each do |os| # postitive opinion status
          positives += session[:user].similarity(os.user)[0]**2 unless session[:user] == os.user
        end
        # **2 molemmille prosenteille suosis korkean prosentin omaavia, eli oli olis parempi vertaisjoukko?
        neg_opinion_statuses = OpinionStatus.find(:all, :conditions => "opinion_id = #{opinion.id} AND status = 2")
        neg_opinion_statuses.each do |os| # postitive opinion status
          negatives += session[:user].similarity(os.user)[0]**2 unless session[:user] == os.user
        end
        # [peer percentage, peer strength]
        combined = positives+negatives
        if combined == 0
          [-1, 0]
        else
          [100*positives/combined, combined/5000]
        end
      end
    end
  end
  
  def peers(opinion)
    if session[:user].nil?
      [nil, 0]
    else
      Opinion
      OpinionStatus
      User
      id = "#{session[:user].id}-#{opinion.id}"
      
      Rails.cache.fetch("peer_percentages[#{id}]") do
        
        user_points = total = trust = 0
        # pos_opinions = [ [opinion, [per,per_change,tot,value]]], ... ]
        pos_cors = Opinion.pos_correlations(opinion.id)
        neg_cors = Opinion.neg_correlations(opinion.id)
        
#        c = [op, [sum, opid_values[1].size, opinion.percentage_all_num] ]
#        per = 100*c[1][0] / c[1][1]
#        diff = per - c[1][2]
#        effect = diff*c[1][1]
        
        # Peruuta annetun vastauksen vaikutus korrelaatioihin (ja sitä kautta vertaisprosenttiin:)
        this_op_stat = OpinionStatus.find_by_user_id_and_opinion_id(session[:user].id, opinion.id)
#        this_op_stat = nil unless this_op_stat.status == 1 or this_op_stat.status == 2


        pos = neg = 0
        
        session[:user].opinion_statuses.each do |os|
          next unless (os.status==1 or os.status == 2)

          c = pos_cors.select { |c| c[0].id == os.opinion_id }[0]
          unless c.nil? #or c[1][3] < 10
            # [op, [sum, opid_values[1].size, opinion.percentage_all_num] ]
            sum = c[1][0]
            answers = c[1][1]
            if not this_op_stat.nil? and this_op_stat.status == 1
              # Peruuta annetun vastauksen vaikutus korrelaatioihin (ja sitä kautta vertaisprosenttiin:)
              sum -= 1 if os.status == 1 # c[1][0]
              answers -= 1 # c[1][1]
            end
#            per = answers == 0 ? 0 : 100*sum / answers
#            diff = per - c[1][2]
#            cor_points = diff * answers
            cor_points = correlation_vars(sum, answers, c[1][2])[2]
            before = user_points
            user_points += os.status == 1 ? cor_points : (os.status == 2 ? -cor_points : 0) # lisätään käyttäjän kokonaispisteisiin; jos käyttäjä eri mieltä mielipiteen kanssa, otetaan negaatio
            if user_points - before < 0
              neg += user_points - before
            else
              pos += user_points - before
            end
            total += cor_points.abs
            trust += sum > 50 ? 50 : sum
          end

          c = neg_cors.select { |c| c[0].id == os.opinion_id }[0]
          unless c.nil? #or c[1][3] < 10
            sum = c[1][0]
            answers = c[1][1]
            if not this_op_stat.nil? and this_op_stat.status == 2
              # Peruuta annetun vastauksen vaikutus korrelaatioihin (ja sitä kautta vertaisprosenttiin:)
              sum -= 1 if os.status == 1 # c[1][0]
              answers -= 1 # c[1][1]
            end
            # [opinion, [per,per_change,tot]]
            cor_points = correlation_vars(sum, answers, c[1][2])[2]
            before = user_points
            user_points = os.status == 2 ? user_points + cor_points : user_points - cor_points
            if user_points - before < 0
              neg += user_points - before
            else
              pos += user_points - before
            end
            total += cor_points.abs # cor_points.abs
            trust += sum > 50 ? 50 : sum
          end
          
        end
        return [nil] if total == 0
        change = 100 * user_points / total
        # change välillä -100..100
        # piennetään luotettavuuden suhteen, jos sen arvo alle 500
        change = (trust>500?500:trust) * change / 500
        
        peer_value = case change
          when -100..-41 then -3
          when -40..-21 then -2
          when -20..-7 then -1
          when -6..6 then 0
          when 7..20 then 1
          when 21..40 then 2
          when 41..100 then 3
          else -999 # error
        end
        [peer_value, change] #, user_points, total, pos, neg, trust]
        
        #peer_percentage = opinion.percentage_all_num + change
#        norm_per = opinion.percentage_all_num
#        peer_percentage = total == 0 ? norm_per : norm_per + ((100-norm_per) * user_points / total)
      end
    end
 
  
  end
  

end
