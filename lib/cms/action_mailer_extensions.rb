module Cms
  module ActionMailerExtensions
    module ClassMethods
    end

    module InstanceMethods
      def receivers(name)
        config_class = "FormConfigs::#{name.classify}".constantize
        to = config_class.first.try(&:emails) || config_class.default_emails
        to
      end
    end
  end
end

ActionMailer::Base.send(:include, Cms::ActionMailerExtensions::InstanceMethods)