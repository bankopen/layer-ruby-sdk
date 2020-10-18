Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  get "test/index"
  post "test/index"
  post "test/callback" 
  
  root 'test#index'
end
