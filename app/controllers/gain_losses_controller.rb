class GainLossesController < ApplicationController
  before_action :set_account

  layout 'accounts'

  def index
    @gain_losses = @account.gain_losses.order(date: :desc, created_at: :desc)
  end

  private

  def set_account
    @account = Account.find(params[:account_id]) if params[:account_id]
  end
end
