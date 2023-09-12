class Lot < ApplicationRecord
  attr_accessor :is_reset
  belongs_to :account
  belongs_to :security
  belongs_to :trade
  validates :date, presence: true

  scope :long, -> { where("quantity > 0")}
  scope :short, -> { where("quantity < 0")}

  after_create :offset!

  def cost_per_unit
    (amount / quantity).abs
  end

  def self.reset_lots!(account)
    account.reload.lots.destroy_all
    account.reload.gain_losses.destroy_all

    account.trades.order(:date, :id).each do |tr|
      if tr.buy_sell?
        new_lot = tr.lots.create(account: account, security: tr.security, quantity: tr.quantity, date: tr.date, amount: tr.amount)
      elsif tr.split?
        Lot.split_lots!(tr)
      elsif tr.conversion_incoming?
        Lot.convert_lots!(tr)
      end
    end
  end

  def self.convert_lots!(tr)
    if tr.conversion_incoming?
      outgoing_conversion_trade = tr.account.trades.conversion.where(security_id: tr.conversion_from_security_id, date: tr.date).first
      return unless outgoing_conversion_trade

      lots_to_convert = outgoing_conversion_trade.security.lots.where(account_id: tr.account_id).order(:date, :id)
      qty_to_convert_from = outgoing_conversion_trade.conversion_from_quantity
      qty_to_convert_to = outgoing_conversion_trade.conversion_to_quantity
      conversion_ratio = qty_to_convert_to / qty_to_convert_from
      qty_converted = 0
      qty_to_convert = qty_to_convert_from

      lots_to_convert.each do |lot|
        break if qty_to_convert == 0
        if lot.quantity <= qty_to_convert
          tr.account.lots.create(trade_id: lot.trade_id, security_id: tr.security_id, quantity: lot.quantity * conversion_ratio, amount: lot.amount, date: lot.date)
          qty_to_convert -= lot.quantity
          lot.destroy
        elsif lot.quantity > qty_to_convert
          amount = lot.amount * (qty_to_convert / lot.quantity)
          tr.account.lots.create(trade_id: tr.id, security_id: tr.security_id, quantity: qty_to_convert * conversion_ratio, amount: amount, date: lot.date)
          lot.amount -= amount
          lot.quantity -= qty_to_convert
          lot.save
          qty_to_convert -= qty_to_convert
        end
      end
    end
  end

  def self.split_lots!(trade)
    return unless trade.split? && trade.split_new_shares.present?

    split_ratio = trade.split_new_shares / trade.prior_quantity_balance
    shares_to_add = trade.split_new_shares - trade.prior_quantity_balance
    used_shares = 0
    lots = trade.security.lots.where(account_id: trade.account_id).order(:date, :id)
    lots.each do |lot|

      if lot == lots.last
        lot.update(quantity: shares_to_add - used_shares + lot.quantity)
      else
        new_quantity = lot.quantity * split_ratio
        used_shares += (lot.quantity * split_ratio) - lot.quantity
        lot.update(quantity: new_quantity)
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
          lot_cost_per_unit = lot.cost_per_unit
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
              cost = quantity.abs * lot_cost_per_unit
              total = proceeds - cost
              account.gain_losses.create(security_id: self.security_id, purchase_date: lot.date, cost: cost, proceeds: proceeds, quantity: quantity, amount: total, trade_id: trade_id, source_trade_id: lot.trade_id, date: date) unless trade.conversion? || trade.split?
              lot.quantity += quantity
              lot.amount += quantity * lot_cost_per_unit
              lot.save
              self.quantity = 0
            else quantity.abs > lot.quantity
              proceeds = lot.quantity * trade.cost_per_unit
              cost = lot.amount
              total =  proceeds - cost
              account.gain_losses.create(security_id: self.security_id, purchase_date: lot.date, cost: cost, proceeds: proceeds, quantity: -lot.quantity, amount: total, trade_id: trade_id, source_trade_id: lot.trade_id, date: date) unless trade.conversion? || trade.split?
              self.quantity += lot.quantity
              self.amount -= lot.quantity * trade.cost_per_unit
              self.save
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
              cost = quantity * lot_cost_per_unit
              total = proceeds - cost
              account.gain_losses.create(security_id: self.security_id, purchase_date: lot.date, cost: cost, proceeds: proceeds, quantity: quantity, amount: total, trade_id: trade_id, source_trade_id: lot.trade_id, date: date) unless trade.conversion? || trade.split?
              lot.quantity += quantity
              lot.amount -= quantity * lot_cost_per_unit
              lot.save
              self.quantity = 0
            else quantity > lot.quantity.abs
              proceeds = lot.amount.abs
              cost = lot.quantity.abs * trade.cost_per_unit
              total = proceeds - cost
              account.gain_losses.create(security_id: self.security_id, purchase_date: lot.date, cost: cost, proceeds: proceeds, quantity: lot.quantity, amount: total, trade_id: trade_id, source_trade_id: lot.trade_id, date: date) unless trade.conversion? || trade.split?
              self.quantity += lot.quantity
              self.amount += lot.quantity * trade.cost_per_unit
              self.save
              lot.destroy
            end
          end
        end
      end
    end
    self.destroy if self.quantity == 0
  end

  def counter_lots
    if quantity > 0
      account.lots.where(security_id: security_id).short.order(:date, :id)
    else
      account.lots.where(security_id: security_id).long.order(:date, :id)
    end
  end

  def short_term?
    date > Date.today - 365.days
  end

  def long_term?
    date < Date.today - 365.days
  end

end
