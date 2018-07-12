module Cms
  class EmailSubscriptionsController < ::Cms::BaseController
    def subscribe
      email = params[:email]
      if email.blank?
        return render json: {}
      end

      #EmailSubscription.create(email: email)
      EmailSubscription.mailchimp_add(email)

      render json: {}
    end

    def unsubscribe

    end
  end
end