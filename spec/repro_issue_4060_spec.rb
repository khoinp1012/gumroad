# frozen_string_literal: true

require "spec_helper"

describe Subscription, type: :model do
  let(:seller) { create(:user) }
  let(:buyer) { create(:user) }
  let(:product) do
    create(:membership_product_with_preset_tiered_pricing,
           user: seller,
           recurrence_price_values: [
             { "monthly": { enabled: true, price: 10 } },
             { "monthly": { enabled: true, price: 5 } }
           ])
  end
  let(:tier) { product.tiers.first }

  before do
    @subscription = create(:subscription, user: buyer, link: product)
    @purchase = create(:test_purchase,
                       link: product,
                       email: buyer.email,
                       price_cents: 1000,
                       is_original_subscription_purchase: true,
                       subscription: @subscription,
                       variant_attributes: [tier])
    @subscription.update!(last_payment_option: @subscription.payment_options.first)
  end

  it "schedules a price update when a deactivated subscription is reactivated with a new tier price" do
    # 1. Deactivate the subscription
    @subscription.cancel_effective_immediately!
    expect(@subscription.reload.deactivated?).to be true

    # 2. Update tier price and enable apply_price_changes_to_existing_memberships
    # Note: price of 10 was 1000 cents. Let's make it 2000 cents.
    tier.save_recurring_prices!({ "monthly": { enabled: true, price: 20 } })
    tier.update!(
      apply_price_changes_to_existing_memberships: true,
      subscription_price_change_effective_date: 8.days.from_now
    )

    # 3. Reactivate
    @subscription.resubscribe!
    @subscription.reload

    # 4. Check that a plan change was scheduled
    plan_change = @subscription.subscription_plan_changes.for_product_price_change.alive.last
    expect(plan_change).to be_present
    expect(plan_change.perceived_price_cents).to eq(2000)
  end
end
