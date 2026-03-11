# frozen_string_literal: true

require "spec_helper"

describe SendPurchaseReceiptJob do
  let(:seller) { create(:named_seller) }
  let(:product) { create(:product, user: seller) }
  let(:purchase) { create(:purchase, link: product, seller: seller) }
  let(:mail_double) { double }

  before do
    allow(mail_double).to receive(:deliver_now)
  end

  context "when the purchase is for a product with stampable PDFs" do
    before do
      allow_any_instance_of(Link).to receive(:has_stampable_pdfs?).and_return(true)
    end

    it "enqueues stamping async and delivers the email immediately" do
      expect(CustomerMailer).to receive(:receipt).with(purchase.id).and_return(mail_double)
      described_class.new.perform(purchase.id)

      expect(StampPdfForPurchaseJob).to have_enqueued_sidekiq_job(purchase.id)
      expect(mail_double).to have_received(:deliver_now)
    end
  end

  context "when the purchase is for a product without stampable PDFs" do
    before do
      allow_any_instance_of(Link).to receive(:has_stampable_pdfs?).and_return(false)
    end

    it "delivers the email without enqueuing stamping" do
      expect(CustomerMailer).to receive(:receipt).with(purchase.id).and_return(mail_double)
      described_class.new.perform(purchase.id)

      expect(StampPdfForPurchaseJob.jobs.size).to eq(0)
      expect(mail_double).to have_received(:deliver_now)
    end
  end

  context "when the purchase is a bundle product purchase" do
    before do
      allow_any_instance_of(Purchase).to receive(:is_bundle_product_purchase?).and_return(true)
    end

    it "doesn't deliver email" do
      expect(CustomerMailer).not_to receive(:receipt).with(purchase.id)
      described_class.new.perform(purchase.id)
    end
  end
end
