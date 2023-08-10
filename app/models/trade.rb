class Trade < ApplicationRecord
  belongs_to :account
  belongs_to :security
  has_many :gain_losses


  attr_accessor :is_recalc
  validates :trade_type, :security_id, :quantity, :price, presence: true

  TYPES = [
    'Buy',
    'Sell'
  ]


  before_validation :set_quantity_sign!
  before_validation :calculate_amount!
  before_save :calculate_quantity_balance! #, if: :quantity_balance_needs_updating?
  before_save :calculate_security_cost!
  after_commit :calculate_remaining_quantity_balances!, unless: :is_recalc
  after_commit :offset_trades!, if: :quantity_balance_needs_updating?

  def quantity_balance_needs_updating?
    if quantity_changed? || date_changed?
      true
    else
      false
    end
  end

  def offset_trades
    if trade_type == 'Buy'
      security.trades.where("quantity < 0 AND date < ? OR ( date = ? AND created_at < ? )", self.date, self.date, self.created_at ||= Time.now).order(date: :asc, created_at: :asc)
    else
      security.trades.where("quantity < 0 AND date < ? OR ( date = ? AND created_at < ? )", self.date, self.date, self.created_at ||= Time.now).order(date: :asc, created_at: :asc)
    end
  end

  def offset_trades!
    return unless offset_trades.any?
    quantity_balance_utilized = 0
    offset_trades.each do |t|
      if t.current_security_balance >= quantity
        t.current_security_balance -= quantity
        t.save
        return
      else
        quantity_balance_utilized = t.current_security_balance
        t.current_security_balance = 0
        t.save
      end
    end
  end


  def calculate_amount!
    self.amount = (self.price * self.quantity) + self.fee + self.other
  end

  def calculate_security_cost!
    self.cost_balance = self.amount
  end

  def average_security_cost_per_share
    amount / quantity
  end

  def set_quantity_sign!
    self.quantity = -self.quantity.abs if self.trade_type == 'Sell'
  end

  def prior_trade
    security.trades.where("account_id = ? AND (date < ? OR ( date = ? AND created_at < ?))", self.account_id, self.date, self.date, self.created_at ||= Time.now).order(date: :desc, created_at: :desc).first
  end

  def prior_balance
    prior_trade.nil? ? 0 : prior_trade.quantity_balance
  end

  def calculate_quantity_balance!
    self.quantity_balance = prior_balance + quantity
  end

  def calculate_remaining_quantity_balances!
    trades = security.trades.where("account_id = ?", self.account_id).order(date: :asc, created_at: :asc)

    trades.each do |t|
      t.calculate_quantity_balance!
      t.is_recalc = true
      t.save
    end
  end
end
