class AiInsightJob < ApplicationJob
  queue_as :ai

  def perform(insight_id, account_id)
    insight = AiInsight.find_by(id: insight_id)
    account = Account.find_by(id: account_id)
    return unless insight && account

    insight.update!(status: :processing)
    content = Ai::JournalAnalyzer.call(account, kind: insight.kind)
    insight.update!(content: content, status: :done, ai_model: account.user.ai_model)
  rescue => e
    insight&.update(status: :failed, content: "Lỗi khi phân tích: #{e.message}")
    Rails.logger.error("AiInsightJob failed: #{e.class} #{e.message}")
  end
end
