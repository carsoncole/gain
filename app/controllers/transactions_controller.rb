class TransactionsController < ApplicationController
  before_action :set_account
  before_action :set_transaction, only: %i[ show edit update destroy ]

  layout 'accounts'

  # GET /transactions or /transactions.json
  def index
    @pagy, @transactions = pagy(@account.transactions.order(date: :desc))
  end

  # GET /transactions/1 or /transactions/1.json
  def show
  end

  # GET /transactions/new
  def new
    @transaction = @account.transactions.new
  end

  # GET /transactions/1/edit
  def edit
  end

  # POST /transactions or /transactions.json
  def create
    @transaction = @account.transactions.new(transaction_params)

    respond_to do |format|
      if @transaction.save
        format.html { redirect_to account_transactions_url(@account), notice: "Transaction was successfully created." }
        format.json { render :show, status: :created, location: @transaction }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @transaction.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /transactions/1 or /transactions/1.json
  def update
    respond_to do |format|
      if @transaction.update(transaction_params)
        format.html { redirect_to account_transaction_url(@account, @transaction), notice: "Transaction was successfully updated." }
        format.json { render :show, status: :ok, location: @transaction }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @transaction.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /transactions/1 or /transactions/1.json
  def destroy
    @transaction.destroy

    respond_to do |format|
      format.html { redirect_to account_transactions_url(@account), notice: "Transaction was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_transaction
      @transaction = @account.transactions.where(id: params[:id]).first
    end

    def set_account
      @account = Account.find(params[:account_id]) if params[:account_id]
    end

    # Only allow a list of trusted parameters through.
    def transaction_params
      params.require(:transaction).permit(:date, :account_id, :security_id, :price, :quantity, :fee, :other, :amount, :security_balance, :cash_balance, :transaction_type)
    end
end