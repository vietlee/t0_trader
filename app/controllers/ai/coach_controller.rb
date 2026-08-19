module Ai
  class CoachController < ApplicationController
    def show
      @messages = current_user.ai_messages.conversation.to_a
      @configured = Anthropic::Client.configured?
    end

    def message
      content = params[:content].to_s.strip
      return redirect_to ai_coach_path if content.blank?

      unless Anthropic::Client.configured?
        return redirect_to ai_coach_path, alert: "Chưa cấu hình ANTHROPIC_API_KEY."
      end

      current_user.ai_messages.create!(role: :user, content: content)
      history = current_user.ai_messages.conversation.to_a
      begin
        reply = Ai::Coach.reply(current_account, history)
        current_user.ai_messages.create!(role: :assistant, content: reply)
      rescue => e
        current_user.ai_messages.create!(role: :assistant, content: "Xin lỗi, gặp lỗi khi gọi AI: #{e.message}")
      end
      redirect_to ai_coach_path
    end
  end
end
