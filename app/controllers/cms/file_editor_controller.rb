module Cms
  class FileEditorController < ::Cms::BaseController
    before_action do
      if respond_to?(:authenticate_user!)
        authenticate_user!
      else
        if !(user_signed_in? && current_user)
          #render_not_found
          if respond_to?(:new_user_session_path)
            redirect_to new_user_session_path
          else
            render_not_found
          end
        end
      end
    end

    before_action :authorize_user!

    def index
      parse_and_normalize_path

      return render "no_access", layout: false unless has_access?
      return render "not_found", layout: false unless @exist

      compute_full_path_entries

      if @is_directory
        initialize_directory_data
      else
        if request.post?
          if validate_file_content
            perform_write_to_file
          else
            return render json: { file_content_error_message: @file_content_error_message }, status: 400
          end

          initialize_file_data(params[:file_content])
        else
          initialize_file_data
        end
      end

      render layout: 'cms/file_editor.html', template: 'cms/file_editor/index.html'
    end

    def create_file
      parse_and_normalize_path

      return render "no_access", layout: false unless has_access?
      return render "not_found", layout: false unless @is_directory
      return render "no_access", layout: false unless can_create_file?
      return render inline: "Bad request", status: 400 unless valid_file_name?

      compute_full_path_entries
      path = calculate_new_file_path
      FileUtils.touch(path) unless File.exists?(path)

      yaml_file_locale = params[:yaml_file_locale].try(:strip)
      if yaml_file_locale.present? && I18n.available_locales.map(&:to_s).index(yaml_file_locale)
        perform_write_to_file("#{yaml_file_locale}:", path)
      end

      redirect_to file_path(path: @relative_path)
    end

    def can_create_file?
      !is_base_dir?(@normalized_path)
    end

    helper_method :can_create_file?

    protected
    def check_if_folder_is_inside_another(target_dir, base_dir = nil)
      base_dir ||= self.base_dir
      base_dir_str = base_dir.to_s
      return false if !target_dir.start_with?(base_dir_str)

      true
    end

    def base_dir
      s = ENV["file_editor_base_dir"] || Rails.root.to_s
      if !s.start_with?("/")
        s = Rails.root.to_s + "/" + s
      end

      s
    end

    def is_base_dir?(path)
      path == base_dir
    end

    def get_relative_path(full_path)
      full_path.gsub(/\A#{base_dir}/, "")
    end

    def is_hidden?(path)
      return false if is_base_dir?(path)
      locales_dir = base_dir + "/locales"
      in_locales = check_if_folder_is_inside_another(path, locales_dir)
      file_name = path.split("/").last
      is_available = in_locales || file_name == "site_data.yml"
      !is_available
    end

    def authorize_user!
      if request.post? && Cms.config.file_editor_use_can_can && !can?(:edit, :files)
        render status: 401, inline: "Not Authorized"
      end
    end

    def parse_and_normalize_path
      @path = params[:path]

      if !@path || @path == ''
        @path = '/'
      elsif !@path.start_with?("/")
        @path = "/" + @path
      end

      @relative_path = @path
      @path = base_dir + @path

      @path_array = @path.split('/')
      if @path_array.first != ''
        @path_array.unshift('')
      end

      if @path_array.last == ''
        @path_array.delete_at(@path_array.count - 1)
      end

      if @path_array.first == ''
        @normalized_path = "#{@path_array.join('/')}"
      else
        @normalized_path = "/#{@path_array.join('/')}"
      end

      @normalized_path_array = @normalized_path.split('/')
      if @normalized_path_array.first != ''
        @normalized_path_array.unshift('')
      end

      @exist = File.exist?(@normalized_path)

      @is_directory = @exist ? File.directory?(@normalized_path) : nil

      @is_file = @exist && !@is_directory
    end

    def get_entries_for_folder(path)
      path_with_star = "#{path}/*"
      Dir.glob(path_with_star)
    end

    def has_access?
      !(!check_if_folder_is_inside_another(@normalized_path) || is_hidden?(@normalized_path))
    end

    def compute_full_path_entries
      @full_path_entries_array = []
      @normalized_path_array.each_with_index do |entry_name, index|
        entry = {}
        entry[:name] = entry_name
        entry[:full_path] = @normalized_path_array[0, index + 1].join('/')
        entry[:is_relative] = check_if_folder_is_inside_another(entry[:full_path])
        entry[:is_base_dir] = is_base_dir?(entry[:full_path])
        entry[:relative_path] = get_relative_path(entry[:full_path])
        entry[:is_directory] = (index == @normalized_path_array.count - 1)? @is_directory : true
        entry[:is_file] = (index == @normalized_path_array.count - 1)? @is_file : false
        entry[:is_system_root] = index == 0
        @full_path_entries_array.push( entry )
      end
    end

    def initialize_directory_data
      @entries = []

      if @normalized_path != '/'
        parent_folder_path_array =  @path_array[0, @path_array.count - 1]
        parent_folder_full_path = parent_folder_path_array.join('/')
        parent_folder_relative_path = get_relative_path(parent_folder_full_path)
        is_base_dir = is_base_dir?(parent_folder_full_path)
        is_relative = check_if_folder_is_inside_another(parent_folder_full_path)
        parent_directory = { name: '..', is_relative: is_relative, is_base_dir: is_base_dir, relative_path: parent_folder_relative_path, full_path: parent_folder_full_path, is_directory: true, is_file: false}

        @entries.push(parent_directory)
      end

      entries = get_entries_for_folder(@normalized_path)

      entries.each do |e|
        entry_url = e

        if entry_url.last == '/'
          entry_url[entry_url.count - 1] = ''
        end

        entry_info = {name: e.split('/').last,
                      full_path: e,
                      is_directory: File.directory?(e),
                      is_file: !File.directory?(e) ,
                      relative_path: get_relative_path(e),
                      is_relative: check_if_folder_is_inside_another(e),
                      is_hidden: is_hidden?(e)
        }

        @entries.push(entry_info)
      end

      @entries_by_type_and_name = @entries.sort() {|e1, e2| ( (e1[:name] == '..')? -1 : (e1[:is_directory] == e2[:is_directory])?    e1[:name] <=> e2[:name] :  (e1[:is_directory] == true)? -1 : 1 )}

      @directories = []
      @files = []

      @entries.each do |e|
        if e[:is_directory] == true
          @directories.push(e)
        else
          @files.push(e)
        end
      end

      @directories_and_files = @directories + @files

      @directory_info = {
        files: @files,
        directories: @directories
      }

      @directory_content = @directories + @files
    end

    def initialize_file_data(file_content = nil)
      @file_content = file_content || File.read(@normalized_path)
      #render inline: @file_content
      @file_name = @normalized_path.split('/').last
      @file_extension = @file_name.split('.').last
      @file_type = :text

      @file_mode = :text

      @ace_mode = :text



      if @file_name.scan(/.js$/).count > 0
        @ace_mode = :javascript
      elsif @file_name.scan(/.html$/).count > 0 || @file_name.scan(/.htm$/).count > 0
        @ace_mode = :html
      elsif @file_name.scan(/.html.erb$/).count > 0
      elsif @file_name.scan(/.haml$/).count > 0
      elsif @file_name.scan(/.slim$/).count > 0
      elsif @file_name.scan(/.yml$/).count > 0
        @ace_mode = :yaml
      elsif @file_name.scan(/.jpe?g$/).count > 0
        @file_type = :image
      elsif @file_name.scan(/.png$/).count > 0
        @file_type = :image
      elsif @file_name.scan(/.gif$/).count > 0
        @file_type = :image
      elsif @file_name.scan(/.svg$/).count > 0
        @file_type = :svg
        @ace_mode = :svg
      elsif @file_name.scan(/.coffee$/).count > 0
        @ace_mode = :coffee
      elsif @file_name.scan(/.sh$/).count > 0
        @ace_mode = :sh
      elsif @file_name.scan(/.css$/).count > 0
        @ace_mode = :css
      elsif @file_name.scan(/.sass$/).count > 0
        @ace_mode = :sass
      elsif @file_name.scan(/.scss$/).count > 0
        @ace_mode = :sass
      elsif @file_name.scan(/.rb$/).count > 0
        @ace_mode = :ruby
      end

      @action = :edit
      @file_editor_file_path = @relative_path
    end

    def validate_file_content(file_content = nil)
      file_content ||= params[:file_content]
      begin
        YAML.load(file_content)
        return true
      rescue Psych::Exception => e
        @file_content_error_message = e.inspect
        return false
      end
    end

    def perform_write_to_file(file_content = nil, file_path = nil)
      file_content ||= params[:file_content]
      file_path ||= @normalized_path
      File.write(file_path, file_content)
      I18n.backend.reload!
      if file_path.scan(/routes\.[a-zA-Z]{2}\.yml/).any?
        Rails.application.routes_reloader.reload!
      end

      if Cms.config.file_editor_clear_cache_method
        Cms.config.file_editor_clear_cache_method.call
      else
        Cms::Caching.clear_cache
      end
    end

    def calculate_new_file_path
      "#{@normalized_path}/#{params[:filename]}"
    end

    def valid_file_name?
      filename = params[:filename]
      filename.present? && (!filename.index('/') || filename.index('/') == 0) && sanitize_filename(filename) == filename
    end

    def sanitize_filename(filename)
      # Split the name when finding a period which is preceded by some
      # character, and is followed by some character other than a period,
      # if there is no following period that is followed by something
      # other than a period (yeah, confusing, I know)
      fn = filename.split /(?<=.)\.(?=[^.])(?!.*\.[^.])/m

      # We now have one or two parts (depending on whether we could find
      # a suitable period). For each of these parts, replace any unwanted
      # sequence of characters with an underscore
      fn.map! { |s| s.gsub /[^a-z0-9\-]+/i, '_' }

      # Finally, join the parts with a period and return the result
      return fn.join '.'
    end
  end
end