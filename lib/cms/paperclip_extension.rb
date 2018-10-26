#Paperclip::Attachment.default_options[:url] = "/:class/:id/:attachment/:style/:basename.:extension"
#Paperclip::Attachment.default_options[:path] = "#{Rails.root}/public:url"
Paperclip::Attachment.default_options[:old_url] = "/system/:attachment/:id/:style/:basename.:extension"
Paperclip::Attachment.default_options[:old_path] = "#{Rails.root}/public#{Paperclip::Attachment.default_options[:old_url]}"

module PaperclipExtension
  def move_images(old_path_pattern = Paperclip::Attachment.default_options[:old_path], new_path_pattern = Paperclip::Attachment.default_options[:path])
    model = self

    if model.try(:attachment_definitions).present?
      puts "model: #{self.name}"
      model.all.each do |instance|
        puts "..id: #{instance.id}"
        model.attachment_definitions.each do |attachment_name, attachment_definition|
          puts "....attachment_name: #{attachment_name}"
          attachment = instance.send(attachment_name)
          style_names = (attachment.styles.keys.map(&:to_s) + ["original"]).uniq
          style_names.each do |style_name|
            puts "......style_name: #{style_name}"
            if old_path_pattern.is_a?(Proc)
              old_path = __cms__call_proc_with_dynamic_arguments(old_path_pattern, style_name, attachment, instance, model)
            else
              old_path = attachment.send(:interpolate, old_path_pattern, style_name) rescue next
            end

            puts "........old_path: #{old_path}; exists: #{File.exists?(old_path).inspect}"

            if File.exists?(old_path)
              if new_path_pattern.is_a?(Proc)
                new_path = __cms__call_proc_with_dynamic_arguments(new_path_pattern, style_name, attachment, instance, model)
              else
                new_path = attachment.send(:interpolate, new_path_pattern, style_name)
              end

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