require "net/http"
require "json"

module Anthropic
  # Wrapper tối giản cho Anthropic Messages API (không cần gem ngoài).
  class Client
    API_URL = "https://api.anthropic.com/v1/messages".freeze
    API_VERSION = "2023-06-01".freeze
    DEFAULT_MODEL = "claude-sonnet-5".freeze

    class Error < StandardError; end

    def self.configured?
      api_key.present?
    end

    def self.api_key
      ENV["ANTHROPIC_API_KEY"].presence
    end

    def self.model
      DEFAULT_MODEL
    end

    # messages: [{ role: "user"/"assistant", content: "..." }]
    # Trả về chuỗi text trả lời.
    def self.chat(system:, messages:, model: self.model, max_tokens: 1500)
      raise Error, "Chưa cấu hình ANTHROPIC_API_KEY" unless configured?

      uri = URI(API_URL)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.read_timeout = 90
      http.open_timeout = 15

      req = Net::HTTP::Post.new(uri)
      req["x-api-key"] = api_key
      req["anthropic-version"] = API_VERSION
      req["content-type"] = "application/json"
      req.body = {
        model: model,
        max_tokens: max_tokens,
        system: system,
        messages: messages
      }.to_json

      res = http.request(req)
      unless res.is_a?(Net::HTTPSuccess)
        raise Error, "API lỗi #{res.code}: #{res.body.to_s[0, 300]}"
      end

      body = JSON.parse(res.body)
      Array(body["content"]).map { |c| c["text"] }.compact.join("\n").presence ||
        raise(Error, "Không nhận được nội dung từ AI")
    end
  end
end
