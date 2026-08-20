class AiReviewMailer < ApplicationMailer
  default from: ENV.fetch("MAIL_FROM", "T0 Trader <noreply@stock.czin.net>")
  helper MarkdownHelper

  def review(user, insight)
    @user = user
    @insight = insight
    headers["X-Entity-Ref-ID"] = "t0trader-review-#{insight.id}"
    headers["Auto-Submitted"] = "auto-generated"
    mail(to: user.email, subject: "Bản đánh giá danh mục từ AI — T0 Trader")
  end
end
