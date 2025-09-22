# config/routes.rb
Rails.application.routes.draw do
  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end

  devise_for :users, skip: [:registrations], controllers: {
    sessions:  "users/sessions",
    passwords: "users/passwords"
  }

  # 👇 Root handling (fixes "Could not find devise mapping" and gives you login as homepage)
  authenticated :user do
    root to: "dashboard#index", as: :authenticated_root
  end

  devise_scope :user do
    root to: "users/sessions#new", as: :unauthenticated_root
  end

  get "dashboard", to: "dashboard#index", as: :dashboard

  namespace :admin do
    resources :users, only: %i[index new create edit update]

    match "scheduler/run", to: "scheduler#run", via: [:get, :post]

    resource :settings, only: %i[show update], controller: "settings" do
      post   :hold_all_schedules
      delete :purge_future_schedules
      post   :toggle_cron
    end

    resources :campaigns, only: %i[index new create show destroy] do
      post :reschedule, on: :member
      post :send_now,   on: :member
    end

    resource :campaign_wizard do
      post :upload_csv
      get  :preview
      get  :configure
      post :configure
      post :finalize
      delete :cancel
    end
  end

  get "/up", to: proc { [200, { "Content-Type" => "text/plain" }, ["OK"]] }
  get "/health", to: proc { [200, { "Content-Type" => "application/json" }, [{ ok: true }.to_json]] }
end