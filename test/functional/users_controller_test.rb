require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  def setup
    activate_authlogic
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create user" do
    assert_difference('User.count') do
      post :create, :user => { :login => "zaphod", :password => "fortytwo", :password_confirmation => "fortytwo", :email => "zaphod@example.com" }
    end

    assert_redirected_to account_path
  end

  test "should show user" do
    UserSession.create(Factory.create(:user))
    get :show
    assert_response :success
  end

  test "should get edit" do
    user = Factory.create(:user)
    UserSession.create(user)
    get :edit, :id => user.id
    assert_response :success
  end

  test "should update user" do
    user = Factory.create(:user)
    UserSession.create(user)
    put :update, :id => user.id, :user => { }
    assert_redirected_to account_path
  end
end
