LOCAL_PATH  = "~/Projects/rails-templates"
REMOTE_PATH = "http://github.com/viking/rails-templates"
JQUERY_VERSION = "1.3.2"

if File.exist?(local = File.expand_path(LOCAL_PATH))
  TEMPLATE_PATH = local
else
  TEMPLATE_PATH = "#{REMOTE_PATH}/raw/master"
end

def template_file(to)
  file to, open("#{TEMPLATE_PATH}/#{to}").read
end

def commit(message)
  git :add => "-u"
  git :add => "."
  git :commit => "-m '#{message}'"
end

run "rm -f log/*"
git :init
commit "Initial commit"

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

gem :authlogic
with_options :source => "http://gems.github.com" do |github|
  github.gem 'thoughtbot-factory_girl', :lib => 'factory_girl'
  github.gem 'sevenwire-forgery',       :lib => 'forgery'
end

generate :session, 'user_session'
generate :model, 'user',
  'login:string', 'email:string', 'crypted_password:string',
  'password_salt:string', 'persistence_token:string', 'login_count:integer',
  'failed_login_count:integer', 'last_request_at:datetime',
  'current_login_at:datetime', 'last_login_at:datetime',
  'current_login_ip:string', 'last_login_ip:string'
generate :controller, 'user_sessions'
generate :controller, 'users'
route "map.resource :user_session"
route "map.resources :users"
route "map.resource :account, :controller => 'users'"

gsub_file 'app/models/user.rb', /^end$/, "  acts_as_authentic\nend"
gsub_file 'test/test_helper.rb', /^(require 'test_help')$/, %{\\1\nrequire "authlogic/test_case"}
template_file 'app/controllers/application_controller.rb'
template_file 'app/controllers/user_sessions_controller.rb'
template_file 'app/controllers/users_controller.rb'
template_file 'app/views/user_sessions/new.html.erb'
template_file 'app/views/users/new.html.erb'
template_file 'app/views/users/edit.html.erb'
template_file 'app/views/users/show.html.erb'
template_file 'app/views/users/_form.html.erb'
template_file 'public/stylesheets/style.css'
template_file 'test/factories.rb'
template_file 'test/functional/user_sessions_controller_test.rb'
template_file 'test/functional/users_controller_test.rb'

run("find . \\( -type d -empty \\) -and \\( -not -regex ./\\.git.* \\) -exec touch {}/.gitignore \\;")
rake "db:migrate"
rake "db:test:prepare"

commit "Applied template"
git :checkout => "-b huge"

rake "test"
