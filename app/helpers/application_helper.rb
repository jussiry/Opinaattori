
# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  
  # global variables:
  $op_per_page = 12
  
  $agree = 1
  $disagree = 2
  $hidden = 3
  
  $act_new_op = 5
  $act_comment = 6
  
  def age(birthdate)
    ((Date.today - birthdate)/365).to_i
  end
  
  def limit_text(text, limit)
    if text.length > limit
      return text[0..(limit-4)] + "..."
    else
      return text
    end
  end
  
  def notice
    if flash[:notice]
      html = "<div id='notice' class='round15 notice_#{flash[:color]}' blindup='true' style='color:#333'> <div>#{flash[:notice]}</div> </div>"
      timer = flash[:timer].nil? ? 15000 : flash[:timer]
      html << "<script type=\"text/javascript\">setTimeout(\"new Effect.Fade('notice');\", #{timer})</script>"
      flash[:notice] = flash[:color] = nil
    end
    html
  end
  
  def format_tag_name(name)
    name.gsub(/_/, ' ') #.capitalize
  end
  
  def link_to_user(user, text='')
    text = user.login_or_new if text.blank?
    link_to text, {:controller => 'user', :login => user.login, :action => 'show'}
  end
  
  def sex(number)
    return "" unless defined? number
    return 'mies' if number == 1
    return 'nainen' if number == 2
  end
  
  def time_ago_text(time)
    ago = Time.now - time
    if ago < 60*60
      "#{(ago/60).to_i} minuuttia"
    elsif ago < 60*60*24
      "#{(ago/60/60).to_i} tuntia"
    else
      "#{(ago/60/60/24).to_i} päivää"
    end
  end
  
  def days_ago(time)
    days = Date.today - time.to_date #Date._load(time.to_s[0..9])
    
    #ago = (Date.today - Date.new(time))#.to_i/60/60/24
    if days < 1
      "Tänään"
    elsif days < 2
      "Eilen"
    else
      "#{days.to_i} päivää sitten" # ago.to_i/60/60/24
    end
  end
  
  def correlation_vars(sum, answers, orig_per) # correlation array
    # cor_a = [agree, answers, original_percentage]
    percent = answers == 0 ? 0 : 100 * sum / answers # cor_a[1] = 
    diff_to_orig = percent - orig_per
    # Huom! 50 vastauksen maksi rajoitus (oletetaan että tällöin prosentti jo vakaa)
#    effect = diff_to_orig * answers
    effect = ((sum > 50 ? 50 : sum) * 100) - (orig_per * answers) # sama kuin diff_to_orig * answers, mutta pyöritykset menee mukavammin
    [percent, diff_to_orig, effect]
  end
end
