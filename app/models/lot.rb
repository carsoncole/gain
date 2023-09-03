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
      if tr.buy_sell_split_conversion?
        new_lot = tr.build_lot(account: account, security: security, quantity: tr.quantity, date: tr.date, amount: tr.amount)
        new_lot.offset!
        new_lot.save if new_lot.quantity != 0
      end
    end

  end

  def offset!
    if counter_lots.any?
      if trade.split? && counter_lots.where(quantity: -quantity, amount: -amount).any?
        identical_counter_lot = counter_lots.where(quantity: -quantity, amount: -amount).first
        identical_counter_lot.destroy
        self.quantity = 0
      else
        counter_lots.each do |lot|
          break if quantity == 0
          if quantity < 0 # Sell trade
            if quantity + lot.quantity == 0
              cost = lot.amount
              proceeds = amount
              total = amount - lot.amount
              account.gain_losses.create(security_id: security_id, purchase_date: lot.date, cost: cost, proceeds: proceeds, quantity: quantity, amount: total, trade_id: trade_id, source_trade_id: lot.trade_id, date: date) unless trade.conversion? || trade.split?
              lot.destroy
              self.quantity = 0
            elsif quantity.abs < lot.quantity
              proceeds = quantity.abs * trade.cost_per_unit
              cost = quantity.abs * lot.trade.cost_per_unit
              total = proceeds - cost
              account.gain_losses.create(security_id: self.security_id, purchase_date: lot.date, cost: cost, proceeds: proceeds, quantity: quantity, amount: total, trade_id: trade_id, source_trade_id: lot.trade_id, date: date) unless trade.conversion? || trade.split?
              lot.quantity += quantity
              lot.amount += quantity * lot.trade.cost_per_unit
              lot.save
              self.quantity = 0
            else quantity.abs > lot.quantity
              proceeds = lot.quantity * trade.cost_per_unit
              cost = lot.amount
              total =  proceeds - cost
              account.gain_losses.create(security_id: self.security_id, purchase_date: lot.date, cost: cost, proceeds: proceeds, quantity: -lot.quantity, amount: total, trade_id: trade_id, source_trade_id: lot.trade_id, date: date) unless trade.conversion? || trade.split?
              self.quantity += lot.quantity
              self.amount -= lot.quantity * trade.cost_per_unit
              lot.destroy
            end
          elsif quantity > 0 # Buy trade
            if quantity + lot.quantity == 0
              proceeds = amount
              cost = lot.amount.abs
              total = proceeds - cost
              account.gain_losses.create(security_id: security_id, purchase_date: lot.date, cost: cost, proceeds: proceeds, quantity: quantity, amount: total, trade_id: trade_id, source_trade_id: lot.trade_id, date: date) unless trade.conversion? || trade.split?
              lot.destroy
              self.quantity = 0
            elsif quantity < lot.quantity.abs
              proceeds = amount
              cost = quantity * lot.trade.cost_per_unit
              total = proceeds - cost
              account.gain_losses.create(security_id: self.security_id, purchase_date: lot.date, cost: cost, proceeds: proceeds, quantity: quantity, amount: total, trade_id: trade_id, source_trade_id: lot.trade_id, date: date) unless trade.conversion? || trade.split?
              lot.quantity += quantity
              lot.amount += quantity * lot.trade.cost_per_unit
              lot.save
              self.quantity = 0
            else quantity > lot.quantity.abs
              proceeds = lot.amount.abs
              cost = lot.quantity.abs * trade.cost_per_unit
              total = proceeds - cost
              account.gain_losses.create(security_id: self.security_id, purchase_date: lot.date, cost: cost, proceeds: proceeds, quantity: lot.quantity, amount: total, trade_id: trade_id, source_trade_id: lot.trade_id, date: date) unless trade.conversion? || trade.split?
              self.quantity += lot.quantity
              self.amount += lot.quantity * trade.cost_per_unit
              lot.destroy
            end
          end
        end
      end
    end
  end

  def counter_lots
    if quantity > 0
      account.lots.where(security_id: security_id).short.order(:date, :id)
    else
      account.lots.where(security_id: security_id).long.order(:date, :id)
    end
  end

end
