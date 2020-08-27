Cms::Engine.routes.draw do
  # scope 'reports' do
  #   scope 'activity', controller: Cms::Reports::ActivityController do
  #
  #   end
  # end

  get "sitemap.xml", to: "sitemap#index", as: :sitemap_xml, format: false
  get "robots", to: "robots#robots_txt", as: :robots_txt, format: "txt"
  if Rails.env.production? && ENV["GOOGLE_WEB_MASTER_ID"].present?
    get "google#{ENV["GOOGLE_WEB_MASTER_ID"]}.html", format: false, to: "google#web_master", as: :google_web_master_confirmation
  end

  if Rails.env.production? && ENV["YANDEX_VERIFICATION_ID"].present?
    get "yandex_#{ENV["YANDEX_VERIFICATION_ID"]}.html", format: false, to: "yandex#verification", as: :yandex_verification
  end

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

  post '/file_editor/create_file(*path)', to: 'file_editor#create_file', as: :create_file
  match '/file_editor/(*path)', to: 'file_editor#index', via: [:get, :post], format: false, as: :file_editor
  match '/file_editor(*path)', to: 'file_editor#index', via: [:get, :post], format: false, as: :file
end