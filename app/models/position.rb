class Position

  def self.all(account, date=Date.today)
    # Trade.joins(:security).order('trades.created_at DESC').pluck("securities.name, trades.quantity_balance")
    # account.trades.order(id: :desc).group(:security_id)
    account.trades.buy_sell.distinct.pluck(:security_id)
  end
end
