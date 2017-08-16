require 'open-uri'
require 'json'

module SensuAPI
  def SensuAPI.query(host, endpoint, http_basic_auth: nil, protocol: 'http', port: 4567)
    url = "#{protocol}://#{host}:#{port}/#{endpoint.join '/'}"

    if http_basic_auth
      connection_stream = open url, http_basic_authentication: http_basic_auth
    else
      connection_stream = open url
    end

    JSON.parse connection_stream.read
  end
end
