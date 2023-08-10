class GainLossesController < ApplicationController
  def index
    @gain_losses = GainLoss.all
  end
end
