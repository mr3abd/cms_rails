Cms::Engine.routes.draw do

  email_subscriptions_scope = ->{
    post "subscribe_on_email_ubscriptions", as: :cms_subscribe_email, to: "email_subscriptions#subscribe"
  }
  if respond_to?(:localized)
    localized(&email_subscriptions_scope)
  else
    email_subscriptions_scope.call
  end

  admin_scope = ->{
    scope "admin" do
      scope "mailchimp", controller: :mailchimp do
        root action: :index, as: :mailchimp
        get "unsubscribe", action: :unsubscribe, as: :mailchimp_unsubscribe
        get "subscribe", action: :subscribe, as: :mailchimp_subscribe
      end
      get "image_sizes", to: "image_sizes#index", as: :image_sizes
    end
  }

  if respond_to?(:localized)
    localized(&admin_scope)
  else
    admin_scope.call
  end

  if Rails.env.production? && ENV["GOOGLE_WEB_MASTER_ID"].present?
    get "google#{ENV["GOOGLE_WEB_MASTER_ID"]}.html", format: false, to: "google#web_master", as: :google_web_master_confirmation
  end

  match '/file_editor/(*path)', to: 'file_editor#index', via: [:get, :post], format: false, as: :file_editor
  match '/file_editor(*path)', to: 'file_editor#index', via: [:get, :post], format: false, as: :file
end