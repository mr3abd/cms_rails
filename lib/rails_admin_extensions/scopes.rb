module RailsAdminExtensions
  module Scopes
    def self.index_controller
      controller do
        proc do
          @objects ||= list_entries
          available_scopes = @model_config.list.scopes
          if available_scopes.present?
            first_scope = available_scopes.first
            if first_scope.is_a?(Array)
              first_scope = first_scope[1]
            end

            if params[:scope].blank?
              if first_scope.is_a?(Proc)
                scope_proc = first_scope
                #@objects = @objects.instance_eval(&scope_proc)
                @objects = scope_proc.call(@objects, _current_user)
              elsif !first_scope.nil?
                @objects = @objects.send(available_scopes.first)
              end
            else
              if available_scopes.is_a?(Hash)
                scope = available_scopes[params[:scope].to_sym]
                if scope.is_a?(Proc)
                  scope_proc = scope
                  @objects = scope_proc.call(@objects, _current_user)
                elsif scope == true
                  @objects = @objects.send(params[:scope])
                end

                #@objects = @objects.instance_eval(&scope_proc)
              elsif available_scopes.is_a?(Array) && @model_config.list.scopes.collect(&:to_s).include?(params[:scope])
                @objects = @objects.send(params[:scope].to_sym)
              end
            end
          end

          respond_to do |format|
            format.html do
              render @action.template_name, status: @status_code || :ok
            end

            format.json do
              output = begin
                if params[:compact]
                  primary_key_method = @association ? @association.associated_primary_key : @model_config.abstract_model.primary_key
                  label_method = @model_config.object_label_method
                  @objects.collect { |o| {id: o.send(primary_key_method).to_s, label: o.send(label_method).to_s} }
                else
                  @objects.to_json(@schema)
                end
              end
              if params[:send_data]
                send_data output, filename: "#{params[:model_name]}_#{DateTime.now.strftime('%Y-%m-%d_%Hh%Mm%S')}.json"
              else
                render json: output, root: false
              end
            end

            format.xml do
              output = @objects.to_xml(@schema)
              if params[:send_data]
                send_data output, filename: "#{params[:model_name]}_#{DateTime.now.strftime('%Y-%m-%d_%Hh%Mm%S')}.xml"
              else
                render xml: output
              end
            end

            format.csv do
              header, encoding, output = CSVConverter.new(@objects, @schema).to_csv(params[:csv_options].permit!.to_h)
              if params[:send_data]
                send_data output,
                          type: "text/csv; charset=#{encoding}; #{'header=present' if header}",
                          disposition: "attachment; filename=#{params[:model_name]}_#{DateTime.now.strftime('%Y-%m-%d_%Hh%Mm%S')}.csv"
              elsif Rails.version.to_s >= '5'
                render plain: output
              else
                render text: output
              end
            end
          end
        end
      end
    end
  end
end