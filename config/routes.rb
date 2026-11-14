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

  namespace :api do
    namespace :v1 do
      get "openapi", to: "openapi#show", as: :openapi
      get "stats", to: "stats#show"
      post "markdown/render", to: "markdown#render_text"

      resources :projects, except: %i[new edit]

      resources :prompts, except: %i[new edit] do
        collection do
          patch :reorder_pinned
        end
        member do
          patch :toggle_pin
          get :attachments, to: "prompt_attachments#index"
          post :attachments, to: "prompt_attachments#create"
          delete "attachments/:attachment_id", to: "prompt_attachments#destroy"
        end
      end
    end
  end
end
