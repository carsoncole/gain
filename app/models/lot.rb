class Lot < ApplicationRecord
  attr_accessor :is_reset
  belongs_to :account
  belongs_to :security
  belongs_to :trade
  validates :date, presence: true

  scope :long, -> { where("quantity > 0")}
  scope :short, -> { where("quantity < 0")}

  def self.reset_lots!(account, security)
    security.lots.where(account: account).destroy_all
    security.gain_losses.where(account: account).destroy_all

    account.trades.where(security: security).order(:date, :id).each do |tr|
      if tr.buy_sell_conversion?
        new_lot = tr.build_lot(account: account, security: security, quantity: tr.quantity, date: tr.date, amount: tr.amount)
        new_lot.offset!
        new_lot.save if new_lot.quantity != 0
      elsif tr.split?
        #nothing
      end
    end

  end

  def offset!
    if counter_lots.any?
      counter_lots.each do |lot|
        break if quantity == 0
        if quantity < 0 # Sell trade
          if quantity + lot.quantity == 0
            total = amount - lot.amount
            account.gain_losses.create(security_id: security_id, quantity: quantity, amount: total, trade_id: trade_id, source_trade_id: lot.trade_id, date: date) unless trade.conversion?
            lot.destroy
            self.quantity = 0
          elsif quantity.abs < lot.quantity
            proceeds = quantity.abs * trade.cost_per_unit
            total = proceeds - (quantity.abs * lot.trade.cost_per_unit)
            account.gain_losses.create(security_id: self.security_id, quantity: quantity, amount: total, trade_id: trade_id, source_trade_id: lot.trade_id, date: date) unless trade.conversion?
            lot.quantity += quantity
            lot.amount += quantity * lot.trade.cost_per_unit
            lot.save
            self.quantity = 0
          else quantity.abs > lot.quantity
            proceeds = lot.quantity * trade.cost_per_unit
            total =  proceeds - lot.amount
            account.gain_losses.create(security_id: self.security_id, quantity: -lot.quantity, amount: total, trade_id: trade_id, source_trade_id: lot.trade_id, date: date) unless trade.conversion?
            self.quantity += lot.quantity
            self.amount -= lot.quantity * trade.cost_per_unit
            lot.destroy
          end
        elsif quantity > 0 # Buy trade
          if quantity + lot.quantity == 0
            total = lot.amount.abs - amount
            account.gain_losses.create(security_id: security_id, quantity: quantity, amount: total, trade_id: trade_id, source_trade_id: lot.trade_id, date: date) unless trade.conversion?
            lot.destroy
            self.quantity = 0
          elsif quantity < lot.quantity.abs
            total = amount - (quantity * lot.trade.cost_per_unit)
            account.gain_losses.create(security_id: self.security_id, quantity: quantity, amount: total, trade_id: trade_id, source_trade_id: lot.trade_id, date: date) unless trade.conversion?
            lot.quantity += quantity
            lot.amount += quantity * lot.trade.cost_per_unit
            lot.save
            self.quantity = 0
          else quantity > lot.quantity.abs
            proceeds = lot.quantity * trade.cost_per_unit
            total = proceeds + lot.amount.abs
            account.gain_losses.create(security_id: self.security_id, quantity: lot.quantity, amount: total, trade_id: trade_id, source_trade_id: lot.trade_id, date: date) unless trade.conversion?
            self.quantity += lot.quantity
            self.amount += lot.quantity * trade.cost_per_unit
            lot.destroy
          end
        end
      end
    end
  end

  def counter_lots
    if quantity > 0
      account.lots.where(security_id: security_id).short.order(:date, :trade_id)
    else
      account.lots.where(security_id: security_id).long.order(:date, :trade_id)
    end
  end

end
