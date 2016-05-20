Paperclip::Attachment.default_options[:url] = "/:class/:id/:attachment/:style/:basename.:extension"
Paperclip::Attachment.default_options[:path] = "#{Rails.root}/public:url"
Paperclip::Attachment.default_options[:old_url] = "/system/:attachment/:id/:style/:basename.:extension"
Paperclip::Attachment.default_options[:old_path] = "#{Rails.root}/public#{Paperclip::Attachment.default_options[:old_url]}"

module PaperclipExtension
  def move_images(old_path_pattern = Paperclip::Attachment.default_options[:old_path], new_path_pattern = Paperclip::Attachment.default_options[:path])
    if self.try(:attachment_definitions).present?
      puts "model: #{self.name}"
      self.all.each do |instance|
        puts "..id: #{instance.id}"
        self.attachment_definitions.each do |attachment_name, attachment_definition|
          puts "....attachment_name: #{attachment_name}"
          attachment = instance.send(attachment_name)
          style_names = (attachment.styles.keys.map(&:to_s) + ["original"]).uniq
          style_names.each do |style_name|
            puts "......style_name: #{style_name}"
            old_path = attachment.send(:interpolate, old_path_pattern, style_name) rescue next
            puts "........old_path: #{old_path}; exists: #{File.exists?(old_path).inspect}"

            if File.exists?(old_path)

              new_path = attachment.send(:interpolate, new_path_pattern, style_name)
              puts "........new_path: #{new_path}"
              new_dirname = File.dirname(new_path)
              unless File.directory?(new_dirname)
                puts "..........creating directory: #{new_dirname}"
                FileUtils.mkdir_p(new_dirname)
              end
              puts "..........moving file '#{old_path}' to '#{new_path}'"
              FileUtils.mv(old_path, new_path)
            end

          end
        end
      end
    end
  end
end

ActiveRecord::Base.send(:extend, PaperclipExtension)