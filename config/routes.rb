Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "prompts#index"

  resources :projects do
    resources :prompts, only: [ :new, :create ]
  end

  resources :prompts do
    collection do
      patch :reorder_pinned
    end
    member do
      patch :toggle_pin
      post :attach_files
      delete "attachments/:attachment_id", to: "prompts#purge_attachment", as: :attachment
    end
  end
end
