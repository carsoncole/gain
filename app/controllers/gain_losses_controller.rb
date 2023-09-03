class GainLossesController < ApplicationController
  before_action :set_account

  layout 'accounts'

  def index
    @gain_losses = @account.gain_losses.order(date: :desc, created_at: :desc)
  end

  def schedule_d
    @years = @account.gain_losses.select(:date, :trade_type).map {|i| i.date.year }.uniq
    @short_term_gain_losses = @account.gain_losses.where("date - purchase_date < 366").order(date: :desc, created_at: :desc)
    @long_term_gain_losses = @account.gain_losses.where("date - purchase_date > 365").order(date: :desc, created_at: :desc)
    if params[:year]
      @year = params[:year]
      @short_term_gain_losses = @short_term_gain_losses.where("strftime('%Y', date) = ?", params[:year])
      @long_term_gain_losses = @long_term_gain_losses.where("strftime('%Y', date) = ?", params[:year])
    end
  end

  private

  def set_account
    @account = current_user.accounts.find(params[:account_id]) if params[:account_id]
  end
end
