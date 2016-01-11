class Cms::Banner < ActiveRecord::Base
  attr_accessible *attribute_names

  belongs_to :attachable, polymorphic: true


  [:image].each do |attachment_name|
    has_attached_file attachment_name
    attr_accessible attachment_name

    do_not_validate_attachment_file_type attachment_name
  end

  #before_save :set_default_title_html_tag

  def set_default_title_html_tag
    self.title_html_tag = "div" if self.title_html_tag.blank?
  end
end
