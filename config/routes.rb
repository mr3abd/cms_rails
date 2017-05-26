Cms::Engine.routes.draw do
  if Rails.env.production? && ENV["GOOGLE_WEB_MASTER_ID"].present?
    get "google#{ENV["GOOGLE_WEB_MASTER_ID"]}.html", format: false, to: "google#web_master", as: :google_web_master_confirmation
  end

  match '/file_editor/(*path)', to: 'file_editor#index', via: [:get, :post], format: false, as: :file_editor
  match '/file_editor(*path)', to: 'file_editor#index', via: [:get, :post], format: false, as: :file
end