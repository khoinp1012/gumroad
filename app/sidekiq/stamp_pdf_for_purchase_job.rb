# frozen_string_literal: true

# Stamps PDF(s) for a purchase. Errors propagate so Sidekiq retries on failure.
class StampPdfForPurchaseJob
  include Sidekiq::Job
  # until_and_while_executing: prevents duplicate enqueue within the same queue AND prevents
  # concurrent execution within the same queue. Cross-queue concurrency (long vs critical) is
  # possible but harmless — find_or_initialize_by in stamp_for_purchase handles the data race.
  sidekiq_options queue: :long, retry: 5, lock: :until_and_while_executing

  def perform(purchase_id)
    purchase = Purchase.find(purchase_id)
    PdfStampingService.stamp_for_purchase!(purchase)

    if Rails.cache.delete(PdfStampingService.notify_buyer_cache_key(purchase_id))
      CustomerMailer.files_ready_for_download(purchase_id).deliver_later(queue: "critical")
      Rails.cache.delete(PdfStampingService.cache_key_for_purchase(purchase_id))
    end
  end
end
