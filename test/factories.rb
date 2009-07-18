Factory.define :user do |f|
  f.login { Forgery(:internet).user_name }
  f.email { |u| u.login + '@' + Forgery(:internet).domain_name }
  f.password 'secret'
  f.password_confirmation 'secret'
end
