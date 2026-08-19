module Ai
  class InsightsController < ApplicationController
    def index
      @insights = AiInsight.recent.limit(30).to_a
      @configured = Anthropic::Client.configured?
      @kinds = AiInsight::KIND_LABELS
    end

    def show
      @insight = AiInsight.find(params[:id])
    end

    def create
      unless Anthropic::Client.configured?
        return redirect_to ai_insights_path, alert: "Chưa cấu hình ANTHROPIC_API_KEY. Thêm key trong biến môi trường để bật AI."
      end

      kind = params[:kind].presence_in(AiInsight.kinds.keys) || "journal"
      insight = AiInsight.create!(kind: kind, status: :queued, period_end: Date.current)
      AiInsightJob.perform_later(insight.id, current_account.id)
      redirect_to ai_insights_path, notice: "Đang phân tích… làm mới trang sau vài giây."
    end
  end
end
