module Cms
  class FileEditorController < ApplicationController
    before_filter do
      if !(user_signed_in? && current_user)
        render_not_found
      end
    end

    def index

      @path = params[:path]

      if !@path || @path == ''
        @path = '/'
      elsif !@path.start_with?("/")
        @path = "/" + @path
      end


      @relative_path = @path
      @path = base_dir + @path

      #return render inline: @path


      @path_array = @path.split('/')
      if @path_array.first != ''
        @path_array.unshift('')
      end


      #@path_array.unshift('/')

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



      path_with_star = "#{@normalized_path}/*"


      path_array_all = @path_array + ['*']
      files = []
      directories = []
      entries = Dir.glob(path_with_star)

      @exist = File.exist?(@normalized_path)

      if !check_if_folder_is_inside_another(@normalized_path) || is_hidden?(@normalized_path)
        return render "no_access", layout: false
      end

      @is_directory = @exist ? File.directory?(@normalized_path) : nil

      @is_file = @exist && !@is_directory

      if !@exist
        return render "not_found", layout: false
      end


      @relative_path_entries_array = []

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

      @parent_directories = []
      #render inline: @normalized_path_array.count.to_s

      @entries = []
      parent_folder_path_array =  @path_array[0, @path_array.count - 1]



      if @is_directory

        if @normalized_path != '/'

          parent_folder_full_path = parent_folder_path_array.join('/')
          parent_folder_relative_path = get_relative_path(parent_folder_full_path)
          is_base_dir = is_base_dir?(parent_folder_full_path)
          is_relative = check_if_folder_is_inside_another(parent_folder_full_path)
          parent_directory = { name: '..', is_relative: is_relative, is_base_dir: is_base_dir, relative_path: parent_folder_relative_path, full_path: parent_folder_full_path, is_directory: true, is_file: false}

          @entries.push(parent_directory)
        end

        entries.each do |e|
          #if File.directory?(e)
          #  directories.push(e.split('/').last)
          entry_url = e
          if entry_url[0] == '/'
            #entry_url[0] = ''



          end

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

          #else
          #files.push(e.split('/').last)
          #end
        end

        #render inline: @entries.inspect

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
            files: files,
            directories: directories
        }

        @directory_content = directories + files


      else
        #@file_content = open("/path/to/file", 'rb') {|io| a = a + io.read}

        if request.method == 'POST'
          file_content = params[:file_content]
          File.write(@normalized_path, file_content)
          I18n.backend.reload!
          Cms::Caching.clear_cache
        end
        @file_content = File.read(@normalized_path)
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





      render layout: 'cms/file_editor', template: 'file_editor/index'
      #render inline: @normalized_path
    end

    protected
    def check_if_folder_is_inside_another(target_dir, base_dir = nil)
      base_dir ||= self.base_dir
      base_dir_str = base_dir.to_s
      return false if !target_dir.start_with?(base_dir_str)

      true
    end

    def base_dir
      ENV["file_editor_base_dir"] || Rails.root.to_s
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
  end
end