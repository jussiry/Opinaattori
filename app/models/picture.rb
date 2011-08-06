require 'mini_magick' # for picture_modification

class Picture < ActiveRecord::Base
  
  validates_format_of :picture_type, :with => /^image/, :allow_blank => true

  def self.uploaded_user_picture(user, picture_field)
    #self.name         = base_part_of(picture_field.original_filename)

    user.small_picture.destroy if user.small_picture
    user.op_picture.destroy if user.op_picture
    user.picture.destroy if user.picture
    user.large_picture.destroy if user.large_picture
    
    image = MiniMagick::Image.from_blob(picture_field.read) #, picture_field.content_type.chomp
    data_type = picture_field.content_type.chomp
    
    resize_by_width(image, 500) # full size (when you click user image on user page)
    user.large_picture = Picture.create(:picture_data => image.to_blob, :picture_type => data_type)
    
    resize_by_width(image, 140) # user page image
    user.picture = Picture.create(:picture_data => image.to_blob, :picture_type => data_type)
    
    resize_by_width(image, 50) # shown next to the opinion:
    crop_height(image, 50)
    user.op_picture = Picture.create(:picture_data => image.to_blob, :picture_type => data_type)
    
    image.resize "18x18\!"  # \! pakottaa vääristämään kuvaa, niin että tulee oikeesti neliö # shown in similar users list:
    user.small_picture = Picture.create(:picture_data => image.to_blob, :picture_type => data_type)
    
    user.save
  end
  
  private
  
  def self.resize_by_width(image, max_width)
    w = image['%w'].to_f
    h = image['%h'].to_f
    if w > max_width
      h = (h*(max_width/w)).to_i
      w = max_width
    end
    image.thumbnail "#{w}x#{h}"
  end
  
  def self.crop_height(image, opt_height)
    cur_height = image['%h'].to_f
    if cur_height > opt_height
      remove = ((cur_height - opt_height)/2).round
      image.shave("0x#{remove}")
    end
  end
  
end
