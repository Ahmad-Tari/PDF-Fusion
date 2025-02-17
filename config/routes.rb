Rails.application.routes.draw do
  root "home#index"
  get "/about", to: "home#about"
  post "upload_csv", to: "home#upload_csv"
  get "download_pdf", to: "home#download_pdf"
  get 'template', to: 'home#template'
   get 'managefile', to: 'home#managefile', as: 'managefile'
    get 'template_1', to: 'home#template_1'
    get 'template_2', to: 'home#template_2'
    get 'template_3', to: 'home#template_3'
  resources :documents, only: [:create, :destroy]

  get "up" => "rails/health#show", as: :rails_health_check
end