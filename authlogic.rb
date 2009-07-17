JQUERY_VERSION = "1.3.2"

file '.gitignore', <<EOF
log/*.log
db/*.sqlite3
tmp/*
config/database.yml
.*swp
EOF

%w{controls dragdrop effects prototype}.each do |name|
  run "rm public/javascripts/#{name}.js"
end
run "rm public/index.html"
run "cp config/database.yml config/database.yml.sample"

file "public/javascripts/jquery-#{JQUERY_VERSION}.js" do
  open("http://jqueryjs.googlecode.com/files/jquery-#{JQUERY_VERSION}.min.js").read
end

#
# authlogic
#
gem :authlogic

# UserSession
generate :session, 'user_session'

# User
generate :model, 'user',
  'login:string', 'email:string', 'crypted_password:string',
  'password_salt:string', 'persistence_token:string',
  'login_count:integer', 'failed_login_count:integer',
  'last_request_at:datetime', 'current_login_at:datetime',
  'last_login_at:datetime', 'current_login_ip:string',
  'last_login_ip:string'
gsub_file 'app/models/user.rb', /^end$/, "  acts_as_authentic\nend"
file 'test/fixtures/users.yml', <<EOF
huge:
  login: huge
  password_salt: <%= salt = "blahfoobarbaz" %>
  crypted_password: <%= Authlogic::CryptoProviders::Sha512.encrypt("small" + salt) %>
  persistence_token: 6cde0674657a8a313ce952df979de2830309aa4c11ca65805dd00bfdc65dbcc2f5e36718660a1d2e68c1a08c276d996763985d2f06fd3d076eb7bc4d97b1e317
  email: huge@example.com
EOF

# UserSessionsController
generate :controller, 'user_sessions'
file('app/controllers/user_sessions_controller.rb', <<EOF)
class UserSessionsController < ApplicationController
  before_filter :require_no_user, :only => [:new, :create]
  before_filter :require_user, :only => :destroy

  def new
    @user_session = UserSession.new
  end

  def create
    @user_session = UserSession.new(params[:user_session])
    if @user_session.save
      flash[:notice] = "Login successful!"
      redirect_back_or_default account_url
    else
      render :action => :new
    end
  end

  def destroy
    current_user_session.destroy
    flash[:notice] = "Logout successful!"
    redirect_back_or_default new_user_session_url
  end
end
EOF
file 'test/functional/user_sessions_controller_test.rb', <<EOF
require 'test_helper'

class UserSessionsControllerTest < ActionController::TestCase
  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create user session" do
    post :create, :user_session => { :login => "huge", :password => "small" }
    assert user_session = UserSession.find
    assert_equal users(:huge), user_session.user
    assert_redirected_to account_path
  end

  test "should destroy user session" do
    delete :destroy
    assert_nil UserSession.find
    assert_redirected_to new_user_session_path
  end
end
EOF
file 'app/views/user_sessions/new.html.erb', <<EOF
<h1>Login</h1>

<% form_for @user_session, :url => user_session_path do |f| %>
  <%= f.error_messages %>
  <%= f.label :login %><br />
  <%= f.text_field :login %><br />
  <br />
  <%= f.label :password %><br />
  <%= f.password_field :password %><br />
  <br />
  <%= f.check_box :remember_me %><%= f.label :remember_me %><br />
  <br />
  <%= f.submit "Login" %>
<% end %>
EOF
route "map.resource :user_session"

# ApplicationController
gsub_file 'app/controllers/application_controller.rb', /^end$/, <<EOF
  helper_method :current_user_session, :current_user
  filter_parameter_logging :password, :password_confirmation

  private
    def current_user_session
      return @current_user_session if defined?(@current_user_session)
      @current_user_session = UserSession.find
    end

    def current_user
      return @current_user if defined?(@current_user)
      @current_user = current_user_session && current_user_session.record
    end

    def require_user
      unless current_user
        store_location
        flash[:notice] = "You must be logged in to access this page"
        redirect_to new_user_session_url
        return false
      end
    end

    def require_no_user
      if current_user
        store_location
        flash[:notice] = "You must be logged out to access this page"
        redirect_to account_url
        return false
      end
    end

    def store_location
      session[:return_to] = request.request_uri
    end

    def redirect_back_or_default(default)
      redirect_to(session[:return_to] || default)
      session[:return_to] = nil
    end
end
EOF

# UsersController
generate :controller, 'users'
file 'app/controllers/users_controller.rb', <<EOF
class UsersController < ApplicationController
  before_filter :require_no_user, :only => [:new, :create]
  before_filter :require_user, :only => [:show, :edit, :update]

  def new
    @user = User.new
  end

  def create
    @user = User.new(params[:user])
    if @user.save
      flash[:notice] = "Account registered!"
      redirect_back_or_default account_url
    else
      render :action => :new
    end
  end

  def show
    @user = @current_user
  end

  def edit
    @user = @current_user
  end

  def update
    @user = @current_user # makes our views "cleaner" and more consistent
    if @user.update_attributes(params[:user])
      flash[:notice] = "Account updated!"
      redirect_to account_url
    else
      render :action => :edit
    end
  end
end
EOF
file 'test/functional/users_controller_test.rb', <<EOF
require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  setup do
    setup :activate_authlogic
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create user" do
    assert_difference('User.count') do
      post :create, :user => { :login => "medium", :password => "small", :password_confirmation => "small", :email => "medium@example.com" }
    end

    assert_redirected_to account_path
  end

  test "should show user" do
    UserSession.create(users(:huge))
    get :show
    assert_response :success
  end

  test "should get edit" do
    UserSession.create(users(:huge))
    get :edit, :id => users(:huge).id
    assert_response :success
  end

  test "should update user" do
    UserSession.create(users(:huge))
    put :update, :id => users(:huge).id, :user => { }
    assert_redirected_to account_path
  end
end
EOF
file 'app/views/users/new.html.erb', <<EOF
<h1>Register</h1>

<% form_for @user, :url => account_path do |f| %>
  <%= f.error_messages %>
  <%= render :partial => "form", :object => f %>
  <%= f.submit "Register" %>
<% end %>
EOF
file 'app/views/users/edit.html.erb', <<EOF
<h1>Edit My Account</h1>

<% form_for @user, :url => account_path do |f| %>
  <%= f.error_messages %>
  <%= render :partial => "form", :object => f %>
  <%= f.submit "Update" %>
<% end %>

<br /><%= link_to "My Profile", account_path %>
EOF
file 'app/views/users/show.html.erb', <<EOF
<p>
  <b>Login:</b>
  <%=h @user.login %>
</p>

<p>
  <b>Login count:</b>
  <%=h @user.login_count %>
</p>

<p>
  <b>Last request at:</b>
  <%=h @user.last_request_at %>
</p>

<p>
  <b>Last login at:</b>
  <%=h @user.last_login_at %>
</p>

<p>
  <b>Current login at:</b>
  <%=h @user.current_login_at %>
</p>

<p>
  <b>Last login ip:</b>
  <%=h @user.last_login_ip %>
</p>

<p>
  <b>Current login ip:</b>
  <%=h @user.current_login_ip %>
</p>


<%= link_to 'Edit', edit_account_path %>
EOF
file 'app/views/users/_form.html.erb', <<EOF
<%= form.label :login %><br />
<%= form.text_field :login %><br />
<br />
<%= form.label :password, form.object.new_record? ? nil : "Change password" %><br />
<%= form.password_field :password %><br />
<br />
<%= form.label :password_confirmation %><br />
<%= form.password_field :password_confirmation %><br />
EOF
route "map.resource :account, :controller => 'users'"
route "map.resources :users"

gsub_file 'test/test_helper.rb', /^(require 'test_help')$/, %{\\1\nrequire "authlogic/test_case"}

run("find . \\( -type d -empty \\) -and \\( -not -regex ./\\.git.* \\) -exec touch {}/.gitignore \\;")
git :init
git :add => "."
git :commit => "-m 'Initial commit'"
git :checkout => "-b huge"

rake "db:migrate"
rake "db:test:prepare"
rake "test"
