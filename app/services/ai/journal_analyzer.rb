module Ai
  # Phân tích nhật ký giao dịch: phát hiện thói quen lời/lỗ, kỷ luật, quản trị vốn.
  class JournalAnalyzer
    SYSTEM = <<~SYS.freeze
      Bạn là chuyên gia phân tích HIỆU SUẤT giao dịch kiêm huấn luyện viên kỷ luật cho một
      nhà đầu tư cá nhân giao dịch cổ phiếu Việt Nam (sàn VNDirect, thị trường thanh toán T+2,
      người dùng đang áp dụng chiến thuật xoay vòng T+0 bằng cách chia nhỏ lệnh và giữ hàng có sẵn).

      Nhiệm vụ: phân tích DỮ LIỆU QUÁ KHỨ của chính người dùng để chỉ ra:
      - Thói quen lặp lại dẫn tới lời/lỗ (cắt lời sớm, gồng lỗ, giao dịch quá nhiều, mua đuổi...).
      - Chất lượng quản trị vốn & rủi ro (kích thước vị thế, phân bổ, phí/thuế bào mòn lợi nhuận).
      - Điểm mạnh nên duy trì và 2-4 hành động cải thiện cụ thể, đo lường được.

      QUY TẮC BẮT BUỘC:
      - Chỉ phân tích dữ liệu/hành vi trong quá khứ. TUYỆT ĐỐI KHÔNG khuyến nghị mua/bán mã cụ thể,
        không dự đoán giá, không tư vấn đầu tư cá nhân hoá. Bạn không phải nhà tư vấn được cấp phép.
      - Viết tiếng Việt, ngắn gọn, dùng markdown (heading ###, bullet, in đậm số liệu chính).
      - Kết thúc bằng 1 dòng nhỏ: "_Đây là phân tích hành vi dựa trên dữ liệu của bạn, không phải khuyến nghị đầu tư._"
    SYS

    PROMPTS = {
      "journal" => "Phân tích tổng thể nhật ký giao dịch của tôi: thói quen lời/lỗ nổi bật, kỷ luật, và 3 việc cần cải thiện.",
      "weekly"  => "Viết bản tổng kết hiệu suất giao dịch của tôi: kết quả chính, điều làm tốt, điều cần sửa cho giai đoạn tới.",
      "pattern" => "Tìm các PATTERN lặp lại trong các lệnh thắng và thua của tôi (theo mã, theo nhãn chiến lược, theo thời gian nắm giữ).",
      "risk"    => "Đánh giá quản trị vốn & rủi ro của tôi: kích thước vị thế, phân bổ danh mục, mức độ phí/thuế bào mòn, và cách kiểm soát rủi ro tốt hơn."
    }.freeze

    def self.call(account, kind: "journal")
      context = PortfolioContext.build(account)
      user_prompt = "#{PROMPTS[kind] || PROMPTS['journal']}\n\nDưới đây là dữ liệu danh mục của tôi:\n\n#{context}"
      Anthropic::Client.chat(
        system: SYSTEM,
        messages: [{ role: "user", content: user_prompt }],
        max_tokens: 1800
      )
    end
  end
end
