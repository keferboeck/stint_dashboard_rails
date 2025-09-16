Rails.application.routes.draw do
  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end

  devise_for :users, skip: [:registrations]

  # ✅ Send signed-in users to the dashboard
  authenticated :user do
    root to: "dashboard#index", as: :authenticated_root
  end

  # ✅ Send visitors to the login page
  unauthenticated do
    devise_scope :user do
      root to: "devise/sessions#new", as: :unauthenticated_root
    end
  end

  get "dashboard", to: "dashboard#index", as: :dashboard

  namespace :admin do
    resources :campaigns, only: %i[index new create show destroy] do
      post :reschedule, on: :member
      post :send_now, on: :member
    end
    resources :users, only: %i[new create]
  end

  get "/health", to: proc { [200, { "Content-Type" => "application/json" }, [{ ok: true }.to_json]] }
end