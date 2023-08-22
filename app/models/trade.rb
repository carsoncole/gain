class Trade < ApplicationRecord
  has_many :gain_losses, dependent: :destroy
  belongs_to :account
  belongs_to :security

  attr_accessor :is_recalc

  validates :date, :trade_type, :security_id, presence: true
  validates :price, :quantity, presence: true, if: -> { trade_type == ['Buy', 'Sell'] }

  scope :buy_sell, -> { where(trade_type: ['Buy', 'Sell'])}

  TYPES = [
    'Buy',
    'Sell',
    'Split'
  ]

  after_initialize :set_defaults!
  before_validation :set_sign!
  before_validation :set_amount_or_price!

  # Update quantity balances
  after_save :calculate_related_quantity_balances!, unless: :is_recalc
  after_destroy :calculate_related_quantity_balances!, unless: :is_recalc

  # Update quantity and cost tax balances
  after_commit :calculate_gains_and_losses!, unless: :is_recalc

  # after_commit :offset_trades!, unless: :is_recalc

  def set_defaults!
    self.date ||= Date.today
    self.trade_type ||= 'Buy'
  end

  def buy?
    trade_type == 'Buy' ? true : false
  end

  def sell?
    trade_type == 'Sell' ? true : false
  end

  def buy_or_sell?
    buy? || sell?
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
    if buy_or_sell?
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

  def set_initial_tax_balances!
    self.quantity_tax_balance = self.quantity
    self.cost_tax_balance = self.amount * (buy? ? 1 : -1)
  end

  def quantity_balance_needs_updating?
    if quantity_changed? || date_changed?
      true
    else
      false
    end
  end

  def related_security_trades
    security.trades.buy_sell.where("account_id = ?", self.account_id).order(date: :asc, created_at: :asc)
  end

  def related_counter_trades
    if trade_type == 'Buy'
      account.trades.buy_sell.where("security_id = ? AND (quantity_tax_balance < 0 AND (date < ? OR ( date = ? AND created_at < ? )))", self.security_id, self.date, self.date, self.created_at ||= Time.now).order(date: :asc, created_at: :asc)
    elsif trade_type == 'Sell'
      account.trades.buy_sell.where("security_id = ? AND (quantity_tax_balance > 0 AND (date < ? OR ( date = ? AND created_at < ? )))", self.security_id, self.date, self.date, self.created_at ||= Time.now).order(date: :asc, created_at: :asc)
    end
  end

  def prior_trade
    security.trades.where("account_id = ? AND (date < ? OR ( date = ? AND created_at < ?))", self.account_id, self.date, self.date, self.created_at ||= Time.now).order(date: :desc, created_at: :desc).first
  end

  def prior_quantity_balance
    prior_trade.nil? ? 0 : prior_trade.quantity_balance
  end

  def cost_per_unit
    (amount / quantity).abs if buy_or_sell?
  end

  def calculate_gains_and_losses!
    # reset all balances to initial values
    related_security_trades.each do |rst|
      rst.set_initial_tax_balances!
      rst.is_recalc = true
      rst.save if rst.changed?
    end

    # process all related trades for tax balances
    account.gain_losses.joins(:trade).where("trades.security_id = ?", self.security_id).destroy_all  # destroy existing gains/losses
    related_security_trades.each do |rst|
      rst.process_gains_and_losses!
    end
  end

  def process_gains_and_losses!
    return unless related_counter_trades.any?
    self.is_recalc = true

    related_counter_trades.each do |t|
      break if quantity_tax_balance == 0
      t.is_recalc = true

      if quantity_tax_balance + t.quantity_tax_balance == 0
        quantity_used = t.quantity_tax_balance
        t.quantity_tax_balance, self.quantity_tax_balance = 0, 0
        gain = -(cost_tax_balance + t.cost_tax_balance)
        t.cost_tax_balance, self.cost_tax_balance = 0,0

      elsif quantity_tax_balance.abs > t.quantity_tax_balance.abs
        quantity_used = t.quantity_tax_balance
        t.quantity_tax_balance = 0
        self.quantity_tax_balance += quantity_used
        proceeds = self.cost_per_unit * quantity_used
        gain = proceeds - t.cost_tax_balance
        t.cost_tax_balance = 0
        self.cost_tax_balance += proceeds

      else # quantity_tax_balance.abs < t.quantity_tax_balance.abs
        quantity_used = quantity_tax_balance
        t.quantity_tax_balance += quantity_used
        self.quantity_tax_balance = 0
        proceeds = cost_tax_balance
        gain = -(proceeds - (t.cost_per_unit * quantity_used))
        t.cost_tax_balance += t.cost_per_unit * quantity_used
        self.cost_tax_balance = 0
      end
      gain_losses.create(account: t.account, date: date, quantity: quantity_used, amount: gain, source_trade_id: t.id)
      t.save
    end
    self.save if self.changed?
  end

  def average_security_cost_per_share
    amount / quantity
  end

  def calculate_quantity_balance!
    self.quantity_balance = prior_quantity_balance + quantity
  end

  def calculate_related_quantity_balances!
    related_security_trades.each do |t|
      t.calculate_quantity_balance!
      t.is_recalc = true
      t.save if t.changed?
    end
  end
end
