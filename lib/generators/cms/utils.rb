module Cms
  module Generators
    module Utils
      module InstanceMethods
        def display(output, color = :green)
          say("           -  #{output}", color)
        end

        def ask_for(wording, default_value = nil, override_if_present_value = nil)
          if override_if_present_value.present?
            display("Using [#{override_if_present_value}] for question '#{wording}'") && override_if_present_value
          else
            ask("           ?  #{wording} Press <enter> for [#{default_value}] >", :yellow).presence || default_value
          end
        end

        def migration_from_string(code, destination, config = {})
          #source  = File.expand_path(find_in_source_paths(source.to_s))

          #set_migration_assigns!(destination)
          #context = instance_eval('binding')

          #dir, base = File.split(destination)
          #numbered_destination = File.join(dir, ["%migration_number%", base].join('_'))

          create_migration destination, nil, config do
            code
          end
        end

        def migration_version
          "[#{Rails::VERSION::MAJOR}.#{Rails::VERSION::MINOR}]"
        end
      end

      module ClassMethods
        def self.next_migration_number(path)
          unless @prev_migration_nr
            @prev_migration_nr = Time.now.utc.strftime("%Y%m%d%H%M%S").to_i
          else
            @prev_migration_nr += 1
          end
          @prev_migration_nr.to_s
        end
      end
    end
  end
end
