class AiReviewJob < ApplicationJob
  queue_as :ai

  # perform(user_id) -> gửi ngay cho 1 user (nút "Gửi ngay").
  # perform()        -> chế độ cron: quét user tới hạn theo tần suất.
  def perform(user_id = nil)
    if user_id
      user = User.find_by(id: user_id)
      generate_and_send(user, force: true) if user
      return
    end

    today = Time.current.in_time_zone("Asia/Ho_Chi_Minh").to_date
    User.find_each do |u|
      freq = u.ai_review_frequency
      due = (freq == "weekly" && today.monday?) || (freq == "monthly" && today.day == 1)
      generate_and_send(u) if due
    end
  end

  private

  def generate_and_send(user, force: false)
    return unless Anthropic::Client.configured?
    return if !force && user.ai_review_frequency == "off"

    account = user.primary_account
    return unless account
    return if account.trades.executed.none?

    content = Ai::JournalAnalyzer.call(account, kind: "weekly")
    insight = user.ai_insights.create!(kind: :weekly, status: :done, content: content,
                                       ai_model: user.ai_model, period_end: Date.current)
    AiReviewMailer.review(user, insight).deliver_now
    Rails.logger.info("AiReviewJob: đã gửi review cho #{user.email}")
  rescue => e
    Rails.logger.error("AiReviewJob lỗi user #{user&.id}: #{e.class} #{e.message}")
  end
end
