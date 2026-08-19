redis_url = ENV.fetch("REDIS_URL", "redis://localhost:6379/1")

Sidekiq.configure_server do |config|
  config.redis = { url: redis_url }

  # Lịch tự động (chỉ chạy trong tiến trình Sidekiq server).
  config.on(:startup) do
    schedule = {
      "fetch_stock_prices" => {
        "cron"  => "*/15 9-15 * * 1-5 Asia/Ho_Chi_Minh", # trong giờ giao dịch
        "class" => "FetchStockPricesJob"
      },
      "check_price_alerts" => {
        "cron"  => "5,20,35,50 9-15 * * 1-5 Asia/Ho_Chi_Minh",
        "class" => "CheckPriceAlertsJob"
      }
    }
    Sidekiq::Cron::Job.load_from_hash!(schedule) if defined?(Sidekiq::Cron::Job)
  end
end

Sidekiq.configure_client do |config|
  config.redis = { url: redis_url }
end
