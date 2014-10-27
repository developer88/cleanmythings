Rails.application.routes.draw do

  root 'slots#index'

  resources :slots, only: [:index, :create], defaults: {format: 'json'}

end
