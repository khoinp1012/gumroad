# frozen_string_literal: true

RSpec.configure do |config|
  config.before(:each) do
    allow(StripePayoutProcessor).to receive(:stripe_balance_negative?).and_return(false)
  end
end
