redis_url = ENV.fetch("REDIS_URL", "redis://localhost:6379/1")

Sidekiq.configure_server do |config|
  config.redis = { url: redis_url }

  # Lịch tự động (chỉ chạy trong tiến trình Sidekiq server).
  config.on(:startup) do
    schedule = {
      "fetch_stock_prices" => {
        "cron"  => "*/2 9-15 * * 1-5 Asia/Ho_Chi_Minh", # mỗi 2' trong giờ giao dịch
        "class" => "FetchStockPricesJob"
      },
      "check_price_alerts" => {
        "cron"  => "1-59/2 9-15 * * 1-5 Asia/Ho_Chi_Minh", # 1' sau mỗi lần lấy giá
        "class" => "CheckPriceAlertsJob"
      }
    }
    Sidekiq::Cron::Job.load_from_hash!(schedule) if defined?(Sidekiq::Cron::Job)
  end
end

Sidekiq.configure_client do |config|
  config.redis = { url: redis_url }
end
