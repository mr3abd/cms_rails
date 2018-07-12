module Cms
  class MailchimpController < ::Cms::BaseController
    before_action :authenticate_user!
    before_action :authorize_user!

    layout false
    def index
      @list = EmailSubscription.mailchimp_list
      @members = @list.members.retrieve.body["members"]
    end

    def subscribe
      EmailSubscription.mailchimp_subscribe(params[:member_email])
      redirect_to send("mailchimp_#{I18n.locale}_path")
    end

    def unsubscribe
      EmailSubscription.mailchimp_unsubscribe(params[:member_email])
      redirect_to send("mailchimp_#{I18n.locale}_path")
    end

    def authorize_user!
      if defined?(CanCan) && current_user.respond_to?(:admin?) && !current_user.admin?
        raise CanCan::AccessDenied
      end
    end
  end
end