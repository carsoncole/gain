class GainLossesController < ApplicationController
  before_action :set_account

  layout 'accounts'

  def index
    @gain_losses = @account.gain_losses.order(date: :desc, created_at: :desc)
  end

  def schedule_d
    @years = @account.gain_losses.select(:date, :trade_type).map {|i| i.date.year }.uniq
    @gain_losses = @account.gain_losses.order(date: :desc, created_at: :desc)
    if params[:year]
      @year = params[:year]
      @gain_losses = @gain_losses.where("strftime('%Y', date) = ?", params[:year])
    end
  end

  private

  def set_account
    @account = Account.find(params[:account_id]) if params[:account_id]
  end
end
