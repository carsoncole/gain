class PositionsController < ApplicationController
  before_action :set_account
  layout 'accounts'

  def index
    if params[:filter]
      @date = Date.new(params[:filter]["date(1i)"].to_i, params[:filter]["date(2i)"].to_i, params[:filter]["date(3i)"].to_i)
      @positions = Position.all(@account, @date)
    else
      first_trade = @account.trades.order(:date).first
      last_trade = @account.trades.order(:date).last
      @start_year = first_trade.date.year if first_trade
      @end_year = last_trade.date.year if last_trade
      @positions = Position.all(@account)
    end
  end

  def set_account
    @account = current_user.accounts.find(params[:account_id]) if params[:account_id]
  end
end
