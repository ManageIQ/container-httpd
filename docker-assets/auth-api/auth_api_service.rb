require "sinatra/base"
require "dbus"
require "json"

class AuthApiService < Sinatra::Base
  DEFAULT_USER_ATTRIBUTES = %w(mail givenname sn displayname domainname).freeze

  set :bind, "0.0.0.0"
  set :port, ENV["HTTPD_AUTH_API_SERVICE_PORT"]

  get "/api/user_attrs/:userid", :provides => 'json' do
    attrs_needed = params[:attributes].nil? ? DEFAULT_USER_ATTRIBUTES : params[:attributes].split(',')

    begin
      ifp_interface = dbus_ifp_interface
      user_attrs = ifp_interface.GetUserAttr(params[:userid], attrs_needed).first
      result = attrs_needed.each_with_object({}) { |attr, hash| hash[attr] = Array(user_attrs[attr]).first }
      body normal_response(result)
    rescue => err
      status 400
      body error_response("Unable to get attributes for user #{params[:userid]} - #{err}")
    end
  end

  get "/api/user_groups/:userid", :provides => 'json' do
    begin
      ifp_interface = dbus_ifp_interface
      user_groups = ifp_interface.GetUserGroups(params[:userid])
      body normal_response(user_groups.first)
    rescue => err
      status 400
      body error_response("Unable to get groups for user #{params[:userid]} - #{err}")
    end
  end

  private

  def dbus_ifp_interface
    sysbus      = DBus.system_bus
    ifp_service = sysbus["org.freedesktop.sssd.infopipe"]
    ifp_object  = ifp_service.object "/org/freedesktop/sssd/infopipe"
    ifp_object.introspect
    ifp_object["org.freedesktop.sssd.infopipe"]
  end

  def error_response(error)
    { "error" => error.split("\n").first }.to_json
  end

  def normal_response(data)
    { "result" => data }.to_json
  end
end

AuthApiService.run!
