module Auth::Api
  extend self

  def error_response(context, status, message)
    init_response(context, status)
    { "error" => message }.to_json
  end

  def success_response(context, json_response)
    init_response(context, 200)
    json_response
  end

  private def init_response(context, status)
    context.response.content_type = "application/json"
    context.response.status_code = status
  end
end
