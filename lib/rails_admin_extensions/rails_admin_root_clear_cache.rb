#require 'rails_admin/config/actions'
module RailsAdmin
  module Config
    module Actions
      class RootClearCache < Base
        RailsAdmin::Config::Actions.register("root_clear_cache", self)

        register_instance_option :object_level do
          true
        end

        register_instance_option :pjax? do
          true
        end

        register_instance_option :root? do
          true
        end

        register_instance_option :collection? do
          false
        end

        register_instance_option :member? do
          false
        end

        register_instance_option :authorized? do
          true
        end

        register_instance_option :visible? do
          true
        end

        register_instance_option :link_icon do
          'icon-move fa fa-file-text-o'
        end

        register_instance_option :http_methods do
          [:get, :post, :patch, :put]
        end

        register_instance_option :controller do
          Proc.new do |klass|
            #def visible_fields
            #  []
            #end

            #klass.class.helper_method :fields

            @cached_pages = Cms::Caching.cached_instances([Service.all, Pages.all_instances])
            if request.method.downcase.in?(%w(post))
              @clear_params = params[:pages]
              if @clear_params.present?
                @clear_params.each do |page_key|
                  page_class_name, page_id = page_key.split("#")
                  page = Object.const_get(page_class_name).find(page_id)
                  page.clear_cache(false)
                end
              end
              @just_now_cleared = true

            end


            if request.method.downcase.in?(%w(post patch put))
              #resource_params = params[:product]
              #@object.properties = resource_params.to_json
              #@object.save
            end

            render "root_clear_cache"

          end
        end


      end
    end
  end
end
