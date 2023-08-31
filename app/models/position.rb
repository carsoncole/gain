class Position

  attr_accessor :security, :quantity


  def initialize(params={})
    self.security = params[:security]
    self.quantity = params[:quantity]
  end

  def self.security_ids(account, date=Date.today)
    account.trades.distinct.pluck(:security_id)
  end

  def self.all(account, date=Date.today)
    result = []
    security_ids(account).each do |id|
      trade = account.trades.where(security_id: id).order(date: :asc, id: :asc).last
      position = Position.new(security: trade.security, quantity: trade.quantity_balance)
      result << position if position.quantity != 0
    end
    result
  end
end
