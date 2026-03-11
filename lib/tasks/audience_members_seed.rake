# frozen_string_literal: true

namespace :audience_members do
  desc "Generate dummy audience data for a seller (SELLER_ID required, COUNT=5000)"
  task seed: :environment do
    seller_id = ENV.fetch("SELLER_ID") { abort "Usage: rake audience_members:seed SELLER_ID=<id> [COUNT=5000]" }
    count = (ENV["COUNT"] || 5000).to_i

    seller = User.find(seller_id)
    products = seller.products.alive.limit(10).to_a
    if products.empty?
      puts "Seller has no products. Creating 5 dummy products..."
      5.times do |i|
        products << seller.products.create!(
          name: "Test Product #{i + 1}",
          price_cents: [500, 1000, 2500, 5000, 10000].sample,
          unique_permalink: "test-product-#{i + 1}-#{SecureRandom.hex(4)}"
        )
      end
    end

    countries = %w[US CA GB DE FR JP AU BR IN MX]
    created = 0

    puts "Creating #{count} audience members for seller #{seller_id}..."

    count.times do |i|
      email = "test-audience-#{i + 1}-#{SecureRandom.hex(4)}@example.com"
      details = {}

      # ~70% are customers with 1-5 purchases
      if rand < 0.7
        num_purchases = rand(1..5)
        details["purchases"] = num_purchases.times.map do
          product = products.sample
          {
            "id" => rand(1..10_000_000),
            "product_id" => product.id,
            "variant_ids" => [],
            "price_cents" => [100, 500, 1000, 2500, 5000, 10000].sample,
            "created_at" => rand(2.years).seconds.ago.iso8601,
            "country" => countries.sample,
          }
        end
      end

      # ~30% are followers
      if rand < 0.3
        details["follower"] = {
          "id" => rand(1..10_000_000),
          "created_at" => rand(2.years).seconds.ago.iso8601,
        }
      end

      # ~15% are affiliates
      if rand < 0.15
        num_affiliates = rand(1..3)
        details["affiliates"] = num_affiliates.times.map do
          product = products.sample
          {
            "id" => rand(1..10_000_000),
            "product_id" => product.id,
            "created_at" => rand(2.years).seconds.ago.iso8601,
          }
        end
      end

      # Ensure at least one role
      if details.empty?
        details["follower"] = {
          "id" => rand(1..10_000_000),
          "created_at" => rand(2.years).seconds.ago.iso8601,
        }
      end

      member = seller.audience_members.build(email: email, details: details)
      member.save!
      created += 1
      puts "Created #{created}/#{count} audience members..." if created % 500 == 0
    end

    puts "Done! Created #{created} audience members for seller #{seller_id}."
    puts "Run `rake audience_members:elasticsearch:backfill` to index them in ES."
  end
end
