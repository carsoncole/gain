class LotsController < ApplicationController
  before_action :set_account
  layout 'accounts'

  def index
    @lots = @account.lots.order(date: :desc, trade_id: :desc)
  end

  private
    def set_account
      @account = Account.find(params[:account_id]) if params[:account_id]
    end
end
