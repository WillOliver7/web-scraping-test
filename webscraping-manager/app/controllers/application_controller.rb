class ApplicationController < ActionController::API
  def authorize_request
    header = request.headers['Authorization']
    token = header.split(' ').last if header

    @decoded = JsonWebToken.decode(token)
    
    if @decoded
      user_id = @decoded[:user_id] || @decoded['user_id']
      email = @decoded[:email] || @decoded['email']
      
      @current_user = { user_id: user_id, email: email }
    else
      render json: { error: 'Token inválido ou expirado' }, status: :unauthorized
    end
  end
end