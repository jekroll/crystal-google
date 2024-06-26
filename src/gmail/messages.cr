require "base64"
require "connect-proxy"
require "../auth/file_auth"
require "../auth/get_token"

module Google::Gmail
  GMAIL_URI = URI.parse("https://gmail.googleapis.com")

  class Messages
    include Auth::GetToken

    def initialize(@auth : Google::Auth | Google::FileAuth | String)
    end

    # API details: https://developers.google.com/gmail/api/reference/rest/v1/users.messages/send
    # sending a RAW RFC 2822 email: https://developers.google.com/gmail/api/reference/rest/v1/users.messages#Message
    # requires scope: https://www.googleapis.com/auth/gmail.send
    def send_request(user_id : String, email : String)
      email = Base64.urlsafe_encode(email)

      HTTP::Request.new(
        "POST",
        "/gmail/v1/users/#{user_id}/messages/send",
        HTTP::Headers{
          "Authorization" => "Bearer #{get_token}",
          "Content-Type"  => "message/rfc822"
        },
        {raw: email}.to_json
      )
    end

    def send(response : HTTP::Client::Response)
      Google::Exception.raise_on_failure(response)
      response.body
    end

    def send(user_id : String, email : String)
      send perform(send_request(user_id, email))
    end

    private def perform(request)
      ConnectProxy::HTTPClient.new(GMAIL_URI) do |client|
        client.exec(request)
      end
    end
  end
end
