class TestController < ApplicationController
  before_action :authorize_request

  def protected_route
    render json: { message: "Se você está vendo isso, o JWT funciona!", user_id: @current_user_id }
  end
end