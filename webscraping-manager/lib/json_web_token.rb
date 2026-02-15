class JsonWebToken
  SECRET_KEY = Rails.application.secret_key_base

  def self.decode(token)
    decoded = JWT.decode(token, SECRET_KEY)[0]
    HashWithIndifferentAccess.new decoded
  rescue
    nil
  end
end