class Markup
  
  def self.no_html(txt, add_paragraphs=false)
    txt.delete! "_*[]" # /[_|*|\[|\]]/
    txt.gsub!(/</, '&lt;')
    txt.gsub!(/>/, '&gt;')
    text = ""
    txt.each(' ') do |w|
      text << w unless w[0..3] == "http"
    end
    text = "<p>"+text+"</p>" if add_paragraphs
    text
  end
  
  def self.html(txt, add_paragraphs=true)
    html = ""
    em = strong = false
    txt.gsub!(/</, '&lt;')
    txt.gsub!(/>/, '&gt;')
    
    txt.split(/\n/).each do |p|
      next if p.empty?
      p.strip!
      html << "<p>" if add_paragraphs
      until p[i||=0].nil? # (defined? i ? i : i=0)
        step = 1
        if p[i] == "["
          if (inner_length = p[i..-1] =~ /\]/).nil?
            i += step
            next
          end
          inner = p[i+1, inner_length-1]
          if inner[0,4] == 'http'
            split_ind = inner =~ / /
            address, text = inner[0, split_ind], inner[(split_ind+1)..-1]
            html << "<a target='_blank' href='#{address}'>#{text}</a>"
          # elsif _numero_  # tee [34] ja [34 jotain_tekstiä]:stä linkit artikkeliin id:llä 34.
          end
          step = inner.length + 2
        elsif p[i] == "*"
          if strong
            html << "</strong>"
            strong = false
          else
            html << "<strong>"
            strong = true
          end
        elsif p[i] == "_"
          if em
            html << "</em>"
            em = false
          else
            html << "<em>"
            em = true
          end
        elsif p[i..i+3] == "http"
          until p[i2||=i] == " " or p[i2||=i].nil?
            i2 += 1
          end
          html << "<a href='#{p[i..i2-1]}'>#{p[i..i2-1]}</a>"
          step = i2 - i
        else
          html << p[i] # "#{p[i].wrapped_string.inspect},"
        end
        i += step
      end # /each
      html << "</strong>" if strong
      html << "</em>" if em
      html << "</p>" if add_paragraphs
    end
    html
  end
  
  def self.html_and_structure(txt)
    
    return ["", [], ""] if txt.nil?
    txt = txt.mb_chars #.to_s
    html = ""
    error = ""
    struct = []
    prev_h2 = nil
    prev_h3 = nil
    
#    h1 = h2 = h3 = h4 = p = a = em = strong = false
#    normal_char = /(\w|,|\.|!)/
    
    txt.split(/\r\n\r\n/).each do |p| # split between paragraphs
      next if p.empty?
      p.strip!
      # titles :
      if p[0,3] =~ /===/
        begin
          prev_h3 << [p[3..-1].to_s.strip]
         id = "h_#{struct.size}#{prev_h2.size-1}#{prev_h3.size-1}"
        rescue
          error = "Otsikot väärässä järjestyksessä! Otsikolla <strong>#{p[3..-1].to_s}</strong> ei ole yhtä korkeamman tason otsikkoa."
        end
        html << "<h4 id='#{id}'>" << p[3..-1] << "</h4>"
      elsif p[0,2] =~ /==/
        begin
          prev_h2 << prev_h3 = [p[2..-1].to_s.strip]
          id = "h_#{struct.size}#{prev_h2.size-1}"
        rescue
          error = "Otsikot väärässä järjestyksessä! Otsikolla <strong>#{p[2..-1].to_s}</strong> ei ole yhtä korkeamman tason otsikkoa."
        end
        html << "<h3 id='#{id}'>" << p[2..-1] << "</h3>"
      elsif p[0,1] =~ /=/
        struct << prev_h2 = [p[1..-1].to_s.strip]
        prev_h3 = nil
        id = "h_#{struct.size}"
        html << "<h2 id='#{id}'>" << p[1..-1] << "</h2>"
      else
        # normal paragraph:
        html << "<p>"
        
        until p[i||=0].nil? # (defined? i ? i : i=0)
          step = 1
          if p[i] == "["
            inner = p[i+1, (p[i..-1] =~ /\]/)-1]
      #        html << inner #.length.to_s
            if inner[0,5] =~ /kuva:/
              html << "<img src='/image/#{inner[5..-1]}' class='text_image' />"
            elsif inner[0,10] =~ /keskikuva:/
              rest = inner[10..-1]
              ind = rest =~ /\:/
              html << "<div class='center'><img src='/image/#{rest[0..ind-1]}' class='center_image' /><div class='pic_text'>#{rest[ind+1..-1]}</div></div>"
            elsif inner[0,10] == 'artikkeli:'
              id, text = inner.split(/ /)
              id = id[10..-1]
              text = Page.find(id).title if text.nil?
              html << "<a href='/page/#{id}'>#{text}</a>"
            elsif inner[0,4] == 'http'
              split_ind = inner =~ / /
              address, text = inner[0, split_ind], inner[(split_ind+1)..-1]
              html << "<a href='#{address}'>#{text}</a>"
            end
            step = inner.length + 2
          else
            html << p[i] # "#{txt[i].wrapped_string.inspect},"
          end
          i += step
        end # /while
        
        html << "</p>"
      end # /else paragraph
    end # /each
    
    html = "<div style='color:red'>#{error} Palaa editointi sivulle ja korjaa otsikoiden tasot oikeiksi.</div>" unless error.empty?
    return [html, struct]
  end




  def vanhaa_koodia
        
    while true
      step = 1
      
      if (i==0 and txt[i] =~ normal_char)
        html << "<p>" + txt[i]
        p = true
      elsif (txt[i,4] =~ /\r\n\r\n/) # two line breaks
        (html << "</p>" and p = false) if p
        if (txt[i+4] =~ normal_char)
          html << "<p>" and p = true
        end
        step = 4
      elsif txt[i] =~ /\[/
        inner = txt[i+1, (txt[i, 600] =~ /\]/)-1]
  #        html << inner #.length.to_s
        if inner[0,4] =~ /img:/
          html << "<img src='/image/#{inner[4..-1]}' class='text_image' />"
        end
        step = inner.length + 2
      else
        html << txt[i] # "#{txt[i].wrapped_string.inspect},"
      end
      i += step
      
      if txt[i].nil?
        html << "</p>" if p
        html << "</h1>" if h1
        html << "</h2>" if h2
        break
      end
    end
    
    html + "  <br/><br/>length: #{txt.length}"
  #    txt.type
  #    (',' =~ normal_char).inspect
  #    txt
  end



end
