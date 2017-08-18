module Auth::Api
  extend self

  private def dbus_ifp_interface
    bus = DBus::Bus.new(LibDBus::BusType::SYSTEM)
    obj = bus.object("org.freedesktop.sssd.infopipe", "/org/freedesktop/sssd/infopipe")
    obj.interface("org.freedesktop.sssd.infopipe")
  end

  get "/api/dbus/user_attrs/:user" do |env|
    user = env.params.url["user"]
    attrs_needed = if env.params.query.has_key?("attributes")
                     env.params.query["attributes"].split(',')
                   else
                     %w(mail givenname sn displayname)
                   end
  
    interface = dbus_ifp_interface
    user_attrs = interface.call("GetUserAttr", [ user, attrs_needed ]).reply[0]
  
    if user_attrs == "No such user"
      error_response(env, 400, "No such user")
    else
      hash_result = Hash(String, String).new
      if user_attrs.is_a? Hash(DBus::Type, DBus::Type)
        user_attrs.each do |key, dbus_value|
          if dbus_value.is_a?(DBus::Variant)
            value = dbus_value.value
            if value.is_a?(Array(DBus::Type))
              hash_result[key.as String] = value.first.as String
            end
          end
        end
      end
      success_response(env, { "result" => hash_result }.to_json)
    end
  end

  get "/api/dbus/user_groups/:user" do |env|
    user = env.params.url["user"]
  
    interface = dbus_ifp_interface
    groups = interface.call("GetUserGroups", [ user ]).reply[0]
  
    if groups.is_a?(Array(DBus::Type))
      success_response(env, { "result" => groups.map { |group| group.as String } }.to_json)
    else
      error_response(env, 500, "Unsupported Dbus type returned by GetUserGroups")
    end
  end
end
