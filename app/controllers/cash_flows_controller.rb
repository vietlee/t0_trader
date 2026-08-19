class CashFlowsController < ApplicationController
  before_action :set_cash_flow, only: [:edit, :update, :destroy]

  def index
    @cash_flows = current_account.cash_flows.recent.to_a
    @capital_in = portfolio.capital_in
    @cash = portfolio.cash
  end

  def new
    @cash_flow = current_account.cash_flows.new(kind: :deposit, occurred_on: Date.current)
  end

  def create
    @cash_flow = current_account.cash_flows.new(cash_flow_params)
    if @cash_flow.save
      redirect_to cash_flows_path, notice: "Đã ghi dòng tiền."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @cash_flow.update(cash_flow_params)
      redirect_to cash_flows_path, notice: "Đã cập nhật."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @cash_flow.destroy
    redirect_to cash_flows_path, notice: "Đã xoá."
  end

  private

  def set_cash_flow
    @cash_flow = current_account.cash_flows.find(params[:id])
  end

  def cash_flow_params
    params.require(:cash_flow).permit(:kind, :amount, :occurred_on, :note)
  end
end
