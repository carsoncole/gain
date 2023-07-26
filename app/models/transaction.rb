class Transaction < ApplicationRecord
  belongs_to :account
  belongs_to :security

  validates :transaction_type, :security_id, :quantity, :price, presence: true

  TYPES = [
    'Buy',
    'Sell'
  ]


  before_validation :calculate_amount!
  before_validation :set_sign!
  before_validation :calculate_security_balance!, unless: :historical?

  def historical?
    self.date < Date.today
  end

  def calculate_amount!
    self.amount = (self.price * self.quantity) + self.fee + self.other
  end

  def set_sign!
    self.quantity = -self.quantity.abs if self.transaction_type == 'Sell'
  end

  def prior_transaction
    security.transactions.where("date <= ? AND created_at < ?", self.date, self.created_at ||= Time.now).order(date: :desc, created_at: :desc).first
  end

  def prior_balance
    prior_transaction.nil? ? 0 : prior_transaction.security_balance
  end

  def calculate_security_balance!
    self.security_balance = prior_balance + quantity
    puts self.security_balance
  end
end
