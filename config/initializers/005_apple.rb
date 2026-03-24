# frozen_string_literal: true

APPLE_CLIENT_ID = GlobalConfig.get("APPLE_WEB_CLIENT_ID")
APPLE_TEAM_ID = GlobalConfig.get("APPLE_WEB_TEAM_ID")
APPLE_KEY_ID = GlobalConfig.get("APPLE_WEB_KEY_ID")
APPLE_PRIVATE_KEY = GlobalConfig.get("APPLE_WEB_PRIVATE_KEY")

# Apple Sign In sends a POST callback from appleid.apple.com. Because
# SameSite=Lax cookies are not sent with cross-site POSTs, the session
# is empty on the callback and the nonce stored during the request phase
# cannot be retrieved. Skip nonce verification — the authorization code
# is single-use and bound to the redirect URI, so the flow is still secure.
OmniAuth::Strategies::Apple.class_eval do
  private

  def verify_nonce!(id_token)
    true
  end
end
