# frozen_string_literal: true

APPLE_CLIENT_ID = GlobalConfig.get("APPLE_WEB_CLIENT_ID")
APPLE_TEAM_ID = GlobalConfig.get("APPLE_WEB_TEAM_ID")
APPLE_KEY_ID = GlobalConfig.get("APPLE_WEB_KEY_ID")
APPLE_PRIVATE_KEY = GlobalConfig.get("APPLE_WEB_PRIVATE_KEY")

APPLE_OAUTH_COOKIE_NAME = "_apple_oauth_nonce"
APPLE_OAUTH_COOKIE_TTL = 300

# Apple Sign In sends a POST callback from appleid.apple.com. Because the
# Rails session cookie is SameSite=Lax, it is not sent with cross-site POSTs
# and the session is empty on the callback. This means the default
# session-based nonce and state verification cannot work.
#
# Fix: generate a single random value used as both the OAuth state parameter
# and the OpenID Connect nonce. Store it in a signed SameSite=None cookie
# that survives the cross-site POST. On callback, two checks run:
#
# 1. State check (callback_phase): cookie value == state POST param.
#    Binds the callback to the browser that started login (CSRF protection).
# 2. Nonce check (verify_nonce!): cookie value == id_token nonce claim.
#    Proves the id_token was issued for this auth request (replay protection).
OmniAuth::Strategies::Apple.class_eval do
  def authorize_params
    @apple_oauth_nonce = SecureRandom.urlsafe_base64(32)
    super.merge(state: @apple_oauth_nonce, nonce: @apple_oauth_nonce)
  end

  def request_phase
    result = super

    signed_nonce = Rails.application.message_verifier("apple_oauth").generate(
      @apple_oauth_nonce, purpose: :apple_oauth, expires_in: APPLE_OAUTH_COOKIE_TTL
    )

    Rack::Utils.set_cookie_header!(result[1], APPLE_OAUTH_COOKIE_NAME, {
      value: signed_nonce, path: "/users/auth/apple", httponly: true,
      secure: request.scheme == "https", same_site: :none, max_age: APPLE_OAUTH_COOKIE_TTL
    })

    result
  end

  def callback_phase
    nonce = cookie_nonce
    state = request.params["state"]

    if nonce.blank? || state.blank? || !ActiveSupport::SecurityUtils.secure_compare(nonce, state)
      return fail!(:csrf_detected, OmniAuth::Strategies::OAuth2::CallbackError.new(:csrf_detected, "CSRF detected"))
    end

    super
  end

  private
    def stored_nonce = cookie_nonce
    def cookie_nonce = Rails.application.message_verifier("apple_oauth").verified(request.cookies[APPLE_OAUTH_COOKIE_NAME], purpose: :apple_oauth)
end
