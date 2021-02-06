# frozen_string_literal: true

class User
  ADMIN_NAME = 'admin'
  private_constant :ADMIN_NAME

  def initialize(basic_auth_header)
    @basic_auth_header = basic_auth_header
  end

  def admin?
    user_name.nil? || user_name == ADMIN_NAME
  end

  def user_name
    return @user_name if defined?(@user_name)
    return @user_name = nil if @basic_auth_header.nil?

    auth_type, credentials = @basic_auth_header.split
    raise "wrong auth type #{auth_type}" unless auth_type.casecmp('basic').zero?

    @user_name = Base64.decode64(credentials).split(':').first
  end
end
