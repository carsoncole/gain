class PositionsController < ApplicationController
  before_action :set_account
  layout 'accounts'

  def index
    @positions = Position.all(@account)
  end

  def set_account
    @account = current_user.accounts.find(params[:account_id]) if params[:account_id]
  end
end
