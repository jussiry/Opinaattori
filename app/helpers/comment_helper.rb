
#require ActionView::Helpers::TextHelper
#include ActionView::Helpers::TextHelper
  
module CommentHelper
  def htmlksi(text)
#    textilize_without_paragraph(text) # "jaa" #
  end
  
#  def text
#    txt = read_attribute(:text)
#    txt.gsub!(/[",*,_]/, '')
#    while first = txt =~ /:http:\/\//
#      last = txt[first..-1] =~ /\s/
#      ending = last.nil? ? "" : txt[first+last..-1]
#      txt = txt[0..first-1] + ending
#    end
#    txt
#  end
#  
#  def text_html
#    rtext = RedCloth.new read_attribute(:text)
#    rtext.to_html.gsub(/<p>/, '').gsub(/<\/p>/, '')
#  end
end
