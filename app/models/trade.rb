class Trade < ApplicationRecord
  has_many :gain_losses, dependent: :destroy
  # has_one :lot, dependent: :destroy
  has_many :lots
  belongs_to :account
  belongs_to :security
  belongs_to :conversion_to_security, class_name: 'Security', optional: true
  belongs_to :conversion_from_security, class_name: 'Security', optional: true

  attr_accessor :is_recalc

  validates :price, :quantity, presence: true, if: -> { trade_type == 'Buy' && amount.blank? }
  validates :date, :trade_type, :security_id, presence: true

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
  before_save :set_sign!, unless: :is_recalc
  before_save :set_amount_or_price!, unless: :is_recalc
  before_save :set_split_values!, if: :split?
  before_save :set_conversion_values!, if: :conversion?
  after_save :calculate_quantity_balances!, unless: :is_recalc
  after_create :add_conversion!, if: :conversion?
  after_destroy :calculate_quantity_balances!
  after_commit :reset_lots!, unless: :is_recalc

  def set_split_values!
    if split? && quantity.blank? && prior_trade
      self.quantity = split_new_shares - prior_quantity_balance
      self.note = "Split #{prior_quantity_balance} for #{split_new_shares} shares"
    end
  end

  def conversion_outgoing?
    conversion? && conversion_to_security_id.present?
  end

  def conversion_incoming?
    conversion? && conversion_from_security_id.present?
  end

  def set_conversion_values!
    if conversion? && quantity.blank?
      self.quantity = -conversion_from_quantity
      new_security = Security.find(conversion_to_security_id)
      self.note = "#{security.name} #{conversion_from_quantity} shrs => #{new_security.name} #{conversion_to_quantity} shrs"
    end
  end

  def add_conversion!
    if conversion? && conversion_to_security_id.present?
      new_security = Security.find(conversion_to_security_id)
      note = "#{security.name} #{conversion_from_quantity} shrs => #{new_security.name} #{conversion_to_quantity} shrs"
      account.trades.create(security_id: conversion_to_security_id, conversion_from_security_id: security_id,quantity: conversion_to_quantity, trade_type: 'Conversion', note: note)
    end
  end

  def reset_lots!
    Lot.reset_lots!(account)
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
    security.trades.where("account_id = ? AND (date < ? OR ( date = ? AND created_at < ?))", self.account_id, self.date, self.date, self.created_at ||= Time.now).order(date: :desc, created_at: :desc).first
  end

  def prior_quantity_balance
    prior_trade.nil? ? 0 : prior_trade.quantity_balance
  end

  def cost_per_unit
    (amount / quantity).abs if buy_sell_split_conversion?
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
