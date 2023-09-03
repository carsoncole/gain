class TradesController < ApplicationController
  before_action :set_account
  before_action :set_trade, only: %i[ show edit update destroy ]

  layout 'accounts'

  # GET /trades or /trades.json
  def index
    @pagy, @trades = pagy(@account.trades.order(date: :desc, created_at: :desc))
    if params[:all]
      @pagy, @trades = pagy(@account.trades.order(date: :desc, created_at: :desc), items: 1000)
    end
  end

  # GET /trades/1 or /trades/1.json
  def show
  end

  # GET /trades/new
  def new
    @trade = @account.trades.new
  end

  # GET /trades/1/edit
  def edit
  end

  # POST /trades or /trades.json
  def create
    @trade = @account.trades.new(trade_params)

    if @trade.conversion?
      @trade.add_conversion_trades!
      redirect_to account_trades_url(@account), notice: "Trade was successfully created."
    elsif @trade.split?
      @trade.add_split_trades!
      redirect_to account_trades_url(@account), notice: "Trade was successfully created."
    elsif @trade.save
      redirect_to account_trade_url(@account, @trade), notice: "Trade was successfully created."
    else
      render :new
    end
  end

  # PATCH/PUT /trades/1 or /trades/1.json
  def update
    respond_to do |format|
      if @trade.update(trade_params)
        format.html { redirect_to account_trade_url(@account, @trade), notice: "Trade was successfully updated." }
      else
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /trades/1 or /trades/1.json
  def destroy
    @trade.destroy

    respond_to do |format|
      format.html { redirect_to account_trades_url(@account), notice: "Trade was successfully destroyed." }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_trade
      @trade = @account.trades.where(id: params[:id]).first
    end

    def set_account
      @account = Account.find(params[:account_id]) if params[:account_id]
    end

    # Only allow a list of trusted parameters through.
    def trade_params
      params.require(:trade).permit(:date, :account_id, :security_id, :price, :quantity, :fee, :other, :amount, :security_balance, :trade_type, :conversion_to_quantity, :conversion_from_quantity, :conversion_to_security_id, :split_new_shares, :note)
    end
end
