# frozen_string_literal: true

# Job used to send the initial receipt email after checkout for a given charge.
# PDF stamping is enqueued asynchronously so the receipt is never delayed.
#
class SendChargeReceiptJob
  include Sidekiq::Job
  sidekiq_options queue: :critical, retry: 5, lock: :until_executed

  def perform(charge_id)
    charge = Charge.find(charge_id)
    return if charge.receipt_sent?

    charge.purchases_requiring_stamping.each do |purchase|
      StampPdfForPurchaseJob.perform_async(purchase.id)
    end

    charge.with_lock do
      CustomerMailer.receipt(nil, charge.id).deliver_now
      charge.update!(receipt_sent: true)
    end
  end
end
