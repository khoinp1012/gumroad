# frozen_string_literal: true

# Sends a receipt email for a purchase.
# PDF stamping is enqueued asynchronously so the receipt is never delayed.
# Exception: a receipt is not sent for bundle product purchases, as they are dummy purchases.
#
class SendPurchaseReceiptJob
  include Sidekiq::Job
  sidekiq_options queue: :critical, retry: 5, lock: :until_executed

  def perform(purchase_id)
    purchase = Purchase.find(purchase_id)

    StampPdfForPurchaseJob.perform_async(purchase_id) if purchase.link.has_stampable_pdfs?
    return if purchase.is_bundle_product_purchase?

    CustomerMailer.receipt(purchase_id).deliver_now
  end
end
