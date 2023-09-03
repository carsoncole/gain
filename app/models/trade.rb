class Trade < ApplicationRecord
  has_many :gain_losses, dependent: :destroy
  has_one :lot, dependent: :destroy
  has_many :lots
  belongs_to :account
  belongs_to :security
  belongs_to :conversion_to_security, class_name: 'Security', optional: true
  belongs_to :conversion_from_security, class_name: 'Security', optional: true

  attr_accessor :is_recalc

  validates :date, :trade_type, :security_id, presence: true
  validates :price, :quantity, presence: true, if: -> { trade_type == ['Buy', 'Sell'] }
  # validates :split_new_shares, presence: true, if: -> { trade_type == 'Split' && quantity != 0 }

  scope :buy_sell, -> { where(trade_type: ['Buy', 'Sell'])}
  scope :splits, -> { where(trade_type: 'Split') }
  scope :conversion, -> { where(trade_type: 'Conversion') }

  TYPES = [
    'Buy',
    'Sell',
    'Split',
    'Conversion'
  ]

  after_initialize :set_defaults!
  before_validation :set_sign!, unless: :is_recalc
  before_save :set_amount_or_price!, unless: :is_recalc
  after_save :calculate_quantity_balances!, unless: :is_recalc
  after_destroy :calculate_quantity_balances!
  after_commit :reset_lots!, unless: :is_recalc

  def reset_lots!
    Lot.reset_lots!(account, security)
  end

  def set_defaults!
    self.date ||= Date.today
    self.trade_type ||= 'Buy'
  end

  def buy?
    trade_type == 'Buy'
  end

  def sell?
    trade_type == 'Sell'
  end

  def buy_sell?
    buy? || sell?
  end

  def buy_sell_conversion?
    buy_sell? || conversion?
  end

  def buy_sell_split_conversion?
    buy_sell_conversion? || split?
  end

  def split?
    trade_type == 'Split'
  end

  def conversion?
    trade_type == 'Conversion'
  end

  def set_sign!
    if self.trade_type == 'Sell'
      self.quantity = -self.quantity.abs
    elsif self.trade_type == 'Buy'
      self.quantity = self.quantity.abs
      self.amount = self.amount.abs if self.amount.present? && self.amount != 0
    end
  end

  def set_amount_or_price!
    if buy_sell?
      self.fee ||= 0
      self.other ||= 0
    end

    if self.amount.present?
      if buy?
        self.price = (amount - fee - other) / quantity
      elsif sell?
        self.price = (amount.abs + fee + other) / quantity.abs
      end
    else
      if buy?
        self.amount = (self.price * self.quantity.abs) + self.fee + self.other
      elsif sell?
        self.amount = (self.price * self.quantity.abs) - self.fee - self.other
      end
    end
  end

  def calculate_quantity_balances!
    related_security_trades.each do |t|
      t.calculate_quantity_balance!
      t.is_recalc = true
      t.save if t.changed?
    end
  end

  def calculate_quantity_balance!
    self.quantity_balance = prior_quantity_balance + quantity if buy_sell_split_conversion?
  end

  def related_security_trades
    security.trades.where("account_id = ?", self.account_id).order(:date, :id)
  end

  def prior_trade
    security.trades.where("account_id = ? AND (date < ? OR ( date = ? AND id < ?))", self.account_id, self.date, self.date, self.id ||= Time.now).order(date: :desc, created_at: :desc).first
  end

  def prior_quantity_balance
    prior_trade.nil? ? 0 : prior_trade.quantity_balance
  end

  def cost_per_unit
    (amount / quantity).abs if buy_sell_split_conversion?
  end

  def add_split_trades!
    return unless split? && split_new_shares.present? && prior_trade.present?

    Lot.reset_lots!(account, security)

    existing_shares_quantity = account.last_trade(security).quantity_balance
    split_ratio = split_new_shares / existing_shares_quantity
    security.lots.where(account: account).order(:date, :id).each do |l|
      old_shares_trade = security.trades.create(account: account, trade_type: 'Split', quantity: -l.quantity, date: l.date, amount: -l.amount)
      new_shares_trade = security.trades.create(account: account, trade_type: 'Split', quantity: l.quantity * split_ratio, date: l.date, amount: l.amount)
    end
  end

  def add_conversion_trades!
    return unless conversion? && !conversion_to_security_id.nil?

    Lot.reset_lots!(account, security)
    Lot.reset_lots!(account, conversion_to_security)

    quantity_converted = 0
    conversion_ratio = conversion_to_quantity / conversion_from_quantity
    account.lots.where(security_id: security_id).order(:date, :id).each do |l|
      break if quantity_converted >= conversion_from_quantity
      quantity_to_be_converted = conversion_from_quantity - quantity_converted
      if l.quantity <= quantity_to_be_converted
        account.trades.create(security_id: conversion_to_security_id, quantity: l.quantity * conversion_ratio, amount: l.amount, trade_type: 'Conversion', conversion_from_security_id: l.security_id, note: "#{conversion_ratio}-to-1 #{security.symbol} >> #{conversion_to_security.symbol} conversion", date: l.date )
        account.trades.create(security_id: security_id, quantity: -l.quantity, amount: -l.amount, trade_type: 'Conversion', note: "#{conversion_ratio}-to-1 #{security.symbol} >> #{conversion_to_security.symbol} conversion", date: l.date )
        quantity_converted += l.quantity
      elsif l.quantity > quantity_to_be_converted
        ratio_to_convert = quantity_to_be_converted / l.quantity
        account.trades.create(security_id: conversion_to_security_id, quantity: quantity_to_be_converted * conversion_ratio, amount: l.amount * ratio_to_convert, trade_type: 'Conversion', conversion_from_security_id: l.security_id, note: "#{conversion_ratio}-to-1 #{security.symbol} >> #{conversion_to_security.symbol} conversion", date: l.date )
        account.trades.create(security_id: security_id, quantity: -quantity_to_be_converted, amount: -l.amount * ratio_to_convert, trade_type: 'Conversion', note: "#{conversion_ratio}-to-1 #{security.symbol} >> #{conversion_to_security.symbol} conversion", date: l.date )
        quantity_converted += quantity_to_be_converted
      end
    end
  end

  def self.to_csv(account)
    attrs = %w{id date trade_type security.name quantity price fee other amount quantity_balance note}

    trades = account.trades.order(:date, :id)
    CSV.generate(write_headers: true, headers: attrs) do |csv|
      method_chains = attrs.map { |a| a.split('.') }
      trades.each do |trade|
        csv << method_chains.map do |chain|
          chain.reduce(trade) { |obj, method_name| obj = obj.try(method_name.to_sym) }
        end
      end
    end
  end
end
