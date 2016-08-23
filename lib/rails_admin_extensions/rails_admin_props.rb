#require 'rails_admin_props/engine'
module RailsAdmin
  module Config
    module Actions
      class Props < Base
        RailsAdmin::Config::Actions.register(self)

        register_instance_option :pjax? do
          false
          true
        end

        register_instance_option :member? do
          true
        end

        register_instance_option :opt? do
          123
        end

        register_instance_option :visible? do
          # current_model = ::RailsAdmin::Config.model(bindings[:abstract_model])
          # authorized? && (current_model.nestable_tree || current_model.nestable_list)
          true
        end

        register_instance_option :controller do
          Proc.new do |klass|
            def visible_fields
              []
            end

            klass.class.helper_method :fields

            #render inline: request.method

            if request.method.downcase.in?(%w(post patch put))
              resource_params = params[:product]
              #render inline: resource_params.inspect
              resource_params.each do |prop_key, prop_value|
                #h = {}
                #prop_id = prop_key.gsub(/\Aprop_/, "").to_i
                #h[prop_key.to_sym] = prop_value.to_i
                option_id = prop_value.to_i
                #ParameterOptionAssignment.joins(:parameters).where({parameters: {id: 1}})
                #parameter_option = TranslatableParameterOption.where(parameter_id: prop_id, value: prop_value).first
                resource = @object
                resource.assign_prop(option_id)
                #resource.parameter_option_assignments.first_or_initialize(parameter_option_id: parameter_option.id)
                #resource.save
              end

            else

            end

            render "props"

            #@my_fields = RailsAdmin::Config::Fields.factory(RailsAdmin::Config.model(Product))
            #@my_field = @my_field.first



            # @nestable_conf = ::RailsAdminNestable::Configuration.new @abstract_model
            # @position_field = @nestable_conf.options[:position_field]
            # @enable_callback = @nestable_conf.options[:enable_callback]
            # @nestable_scope = @nestable_conf.options[:scope]
            # @options = @nestable_conf.options
            # @adapter = @abstract_model.adapter
            #
            # # Methods
            # def update_tree(tree_nodes, parent_node = nil)
            #   tree_nodes.each do |key, value|
            #     model = @abstract_model.model.find(value['id'].to_s)
            #     model.parent = parent_node || nil
            #     model.send("#{@position_field}=".to_sym, (key.to_i + 1)) if @position_field.present?
            #     model.save!(validate: @enable_callback)
            #     update_tree(value['children'], model) if value.has_key?('children')
            #   end
            # end
            #
            # def update_list(model_list)
            #   model_list.each do |key, value|
            #     model = @abstract_model.model.find(value['id'].to_s)
            #     model.send("#{@position_field}=".to_sym, (key.to_i + 1))
            #     model.save!(validate: @enable_callback)
            #   end
            # end
            #
            # if request.post? && params['tree_nodes'].present?
            #   begin
            #     update = ->{
            #       update_tree params[:tree_nodes] if @nestable_conf.tree?
            #       update_list params[:tree_nodes] if @nestable_conf.list?
            #     }
            #
            #     ActiveRecord::Base.transaction { update.call } if @adapter == :active_record
            #     update.call if @adapter == :mongoid
            #
            #     message = "<strong>#{I18n.t('admin.actions.nestable.success')}!</strong>"
            #   rescue Exception => e
            #     message = "<strong>#{I18n.t('admin.actions.nestable.error')}</strong>: #{e}"
            #   end
            #
            #   render text: message
            # end
            #
            # if request.get?
            #   query = list_entries(@model_config, :nestable, false, false).reorder(nil)
            #
            #   case @options[:scope].class.to_s
            #     when 'Proc'
            #       query.merge!(@options[:scope].call)
            #     when 'Symbol'
            #       query.merge!(@abstract_model.model.public_send(@options[:scope]))
            #   end
            #
            #   if @nestable_conf.tree?
            #     @tree_nodes = if @options[:position_field].present?
            #                     query.arrange(order: @options[:position_field])
            #                   else
            #                     query.arrange
            #                   end
            #   end
            #
            #   if @nestable_conf.list?
            #     @tree_nodes = query.order("#{@options[:position_field]} ASC")
            #   end
            #
            #   render action: @action.template_name
            # end
          end
        end

        register_instance_option :link_icon do
          'icon-move fa fa-arrows'
        end

        register_instance_option :http_methods do
          [:get, :post, :patch, :put]
        end

        register_instance_option :visible? do
          current_model = ::RailsAdmin::Config.model(bindings[:abstract_model])
          authorized? && (current_model.nestable_tree || current_model.nestable_list)
        end
      end
    end
  end
end
