Cms::Engine.routes.draw do
  match '/file_editor/(*path)', to: 'file_editor#index', via: [:get, :post], format: false, as: :file_editor
  match '/file_editor(*path)', to: 'file_editor#index', via: [:get, :post], format: false, as: :file
end