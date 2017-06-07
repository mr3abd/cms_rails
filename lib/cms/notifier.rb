module Cms
  module Notifier
    def notify_admin
      ApplicationMailer.send("new_#{self.class.name.underscore}", self).deliver
    end
  end
end