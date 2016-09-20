class ApplicationController < ActionController::Base
  include Trailblazer::Operation::Controller

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_action :mock_shibboleth, if: -> { Rails.env.development? || Rails.env.test? }
  before_action :expose_current_user

  attr_accessor :current_user
  helper_method :current_user
  def current_user
    CurrentUser.new(request)
  end

  def mock_shibboleth
    unless request.headers.include?('REMOTE_USER') || request.headers.include?('HTTP_REMOTE_USER')
      request.set_header('REMOTE_USER', 'isaac')
      request.set_header('Shib-commonName', 'Sir Isaac Newton')
      request.set_header('Shib-homeOrganization', 'university-example.org')
      request.set_header('Shib-eduPersonEntitlement', 'urn:mace:dir:entitlement:common-lib-terms-example')
      request.set_header('Shib-eduPersonTargetedID', '56c00c40d7051ca1f554d7b79a5d754b1e54966c')
    end
  end

  def expose_current_user
    params[:current_user] = current_user
  end
end
