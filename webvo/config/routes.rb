ActionController::Routing::Routes.draw do |map|
  # The priority is based upon order of creation: first created -> highest priority.

  map.connect 'ruby/form_scheduled.rb', 
    :controller => 'scheduled_program',
    :action => 'list'

  map.connect 'ruby/form_scheduled.rb.:format', 
    :controller => 'scheduled_program',
    :action => 'list'

  map.connect 'ruby/add_recording.rb', 
    :controller => 'scheduled_program',
    :action => 'add'

  map.connect 'ruby/add_recording.rb.:format', 
    :controller => 'scheduled_program',
    :action => 'add'

  map.connect 'ruby/delete_recording.rb', 
    :controller => 'scheduled_program',
    :action => 'remove'

  map.connect 'ruby/delete_recording.rb.:format', 
    :controller => 'scheduled_program',
    :action => 'remove'

  map.connect 'ruby/form_listing.rb', 
    :controller => 'schedule',
    :action => 'list'

  map.connect 'ruby/form_listing.rb.:format', 
    :controller => 'schedule',
    :action => 'list'

  map.connect 'ruby/form_stats.rb', 
    :controller => 'schedule',
    :action => 'stats'

  map.connect 'ruby/form_stats.rb.:format', 
    :controller => 'schedule',
    :action => 'stats'

  map.connect 'ruby/form_search.rb', 
    :controller => 'schedule',
    :action => 'search'

  map.connect 'ruby/form_search.rb.:format', 
    :controller => 'schedule',
    :action => 'search'

  map.connect 'ruby/form_recorded.rb', 
    :controller => 'recorded_program',
    :action => 'list'

  map.connect 'ruby/form_recorded.rb.:format', 
    :controller => 'recorded_program',
    :action => 'list'

  # Sample of regular route:
  #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   map.resources :products

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  # map.root :controller => "welcome"

  # See how all your routes lay out with "rake routes"

  # Install the default routes as the lowest priority.
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
