class PositionsController < ApplicationController
  before_action :set_account
  layout 'accounts'

  def index
    @positions = @account.holdings_as_security_ids
  end

  def set_account
    @account = Account.find(params[:account_id]) if params[:account_id]
  end
end
