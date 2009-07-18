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
    UserSession.create(users(:zaphod))
    get :show
    assert_response :success
  end

  test "should get edit" do
    UserSession.create(users(:zaphod))
    get :edit, :id => users(:zaphod).id
    assert_response :success
  end

  test "should update user" do
    UserSession.create(users(:zaphod))
    put :update, :id => users(:zaphod).id, :user => { }
    assert_redirected_to account_path
  end
end
