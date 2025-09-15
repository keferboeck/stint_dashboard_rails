Rails.application.routes.draw do
  devise_for :users

  namespace :admin do
    resources :campaigns, only: %i[index new create show destroy] do
      post :reschedule, on: :member
      post :send_now, on: :member
    end
  end

  get '/health', to: proc { [200, { 'Content-Type' => 'application/json' }, [{ ok: true }.to_json]] }
  root to: redirect('/admin/campaigns')
end