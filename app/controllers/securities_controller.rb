class SecuritiesController < ApplicationController
  before_action :set_security, only: %i[ show edit update destroy ]
  layout 'settings'

  # GET /securities or /securities.json
  def index
    @securities = current_user.securities.order(:name)
  end

  # GET /securities/1 or /securities/1.json
  def show
  end

  # GET /securities/new
  def new
    @security = current_user.securities.new
  end

  # GET /securities/1/edit
  def edit
  end

  # POST /securities or /securities.json
  def create
    @security = current_user.securities.new(security_params)

    respond_to do |format|
      if @security.save
        format.html { redirect_to securities_url, notice: "Security was successfully created." }
      else
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /securities/1 or /securities/1.json
  def update
    respond_to do |format|
      if @security.update(security_params)
        format.html { redirect_to securities_url, notice: "Security was successfully updated." }
      else
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /securities/1 or /securities/1.json
  def destroy
    @security.destroy

    respond_to do |format|
      format.html { redirect_to securities_url, notice: "Security was successfully destroyed." }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_security
      @security = current_user.securities.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def security_params
      params.require(:security).permit(:name, :symbol, :currency_id)
    end
end
