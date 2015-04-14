Web::Application.routes.draw do
  get "password_resets/new"
  root :to => 'main#index'

  post "filters/save" => "filters#save", :as => "save_filters"
  put "budgets/envelopes/:envelope_id" => "budgets#update"
  put "allocation_plans/:allocation_plan_id/envelopes/:envelope_id" => "allocation_plan_items#update"
  match "reports/:action" => "reports#%{action}", via: [:get, :post]
  get '/banks/:id/notes' => "banks#notes" 
  get '/upgrade' => 'subscriptions#index', :as => :upgrade
  get '/subscriptions/check' => 'subscriptions#check'
  post '/subscriptions/notify' => "subscriptions#notify"

  resources :filters, :users, :reports, :budgets, :sessions, :subscriptions, :password_resets
  
  resources :allocation_plans do
    resources :allocation_plan_items
  end

  resources :imports do
    collection do
       get :linked_import
       post :linked_import_start
    end
  end

  resources :transactions do
    collection do
      post :assign
    end
    member do
      get :delete
    end
  end

  resources :transfers do
    member do
      get :delete
    end
  end

  resources :allocations do
    member do
      get :delete
    end
  end

  resources :incomes do
    member do
      get :delete
    end
  end

  resources :envelope_groups do
    collection do
      post :reorder
    end
    member do
      get :delete
    end
  end
  
  resources :envelopes do
    member do
      get :delete
    end
    collection do
       get :funded_amounts
       post :reorder
    end
    resources :transactions
  end

  resources :accounts do
    member do
      get :delete
      get :convert_to_linked
    end
    collection do
      get :new_linked
      post :linked_bank_accounts, :linked_bank_balance
    end
    resources :transactions
  end

  get '/settings' => "users#edit",      :as => :settings
  patch '/settings' => "users#update"
  get '/delete' => "users#delete",      :as => :delete_user
  delete '/delete' => "users#destroy"
  get '/signup'   => "users#new",       :as => :signup
  get '/signin'   => "sessions#new",    :as => :signin
  get '/signout'  => "sessions#destroy",:as => :signout

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))' 
end
