# Puma configuration. https://puma.io/puma/Puma/DSL.html

threads_count = ENV.fetch("RAILS_MAX_THREADS", 3)
threads threads_count, threads_count

plugin :tmp_restart

if ENV.fetch("RAILS_ENV", "development") == "production"
  # Production: chạy sau nginx qua unix socket + nhiều worker.
  # Đường dẫn socket/pid lấy từ .env (tuyệt đối) để không phụ thuộc symlink.
  workers ENV.fetch("WEB_CONCURRENCY", 2)
  preload_app!

  bind "unix://#{ENV.fetch('PUMA_SOCKET', '/var/www/t0_trader/shared/tmp/sockets/puma.sock')}"
  pidfile ENV.fetch("PIDFILE", "/var/www/t0_trader/shared/tmp/pids/puma.pid")
  state_path ENV.fetch("PUMA_STATE", "/var/www/t0_trader/shared/tmp/pids/puma.state")

  on_worker_boot do
    ActiveRecord::Base.establish_connection if defined?(ActiveRecord)
  end
else
  # Development: cổng TCP.
  port ENV.fetch("PORT", 3000)
  pidfile ENV["PIDFILE"] if ENV["PIDFILE"]
end
