ActionController::Routing::Routes.draw do |map|

  map.root :controller => 'posts', :action => 'dashboard'
  map.connect '/callback', :controller => 'engagements', :action => 'callback'
  map.connect '/posts/show', :controller => 'posts', :action => 'show',  :conditions => { :method => :get }
  map.connect '/posts/send_invites', :controller => 'posts', :action => 'send_invites'
  map.connect '/posts/plaxo', :controller => 'posts', :action => 'plaxo'
  map.connect '/users/contacts', :controller => 'users', :action => 'contacts',  :conditions => { :method => :get }
  map.connect '/users/groups', :controller => 'users', :action => 'groups',  :conditions => { :method => :get }
  map.resources :comments, :collection => {:set_comment_body => :post}
  map.resources :users, :collection => {:activate => :post, :resendnewactivation => :get, :resendactivation => :post, :display_profile => :get}
  map.resources :posts, :has_many => 'comments', :collection => {:migrate_existing_contacts => :get}
  map.resources :engagements, :collection => { :get_followers => :get, :resend_invite => :post, :get_auth_from_twitter => :get }
  map.resources :user_sessions
  map.resources :password_resets
  #map.resources :groups, :collection => { :add_contact_to_groups => :get}

  map.about "about", :controller => 'posts', :action => 'about'
  map.privacy "privacy", :controller => 'posts', :action => 'privacy'
  map.blog "blog", :controller => 'posts', :action => 'blog'
  map.contact "contact", :controller => 'posts', :action => 'contact'
  map.help "help", :controller => 'posts', :action => 'help'
  map.login "login",   :controller => 'user_sessions', :action => 'new'
  map.logout "logout", :controller => 'user_sessions', :action => 'destroy'
  map.admin "admin", :controller => 'posts', :action => 'admin'

  map.activate '/activate/:activation_code', :controller => 'users', :action => 'activate' 

  # The priority is based upon order of creation: first created -> highest priority.

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

  # Sample resource route with more complex sub-resources
  #   map.resources :products do |products|
  #     products.resources :comments
  #     products.resources :sales, :collection => { :recent => :get }
  #   end

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  # map.root :controller => "welcome"

  # See how all your routes lay out with "rake routes"

  # Install the default routes as the lowest priority.
  # Note: These default routes make all actions in every controller accessible via GET requests. You should
  # consider removing or commenting them out if you're using named routes and resources.
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
  map.error ':controllername',  :controller => 'posts', :action => '404'
  map.connect '*path' , :controller => 'posts', :action => '404'

end
