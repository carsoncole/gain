class Transaction < ApplicationRecord
  belongs_to :account
  belongs_to :security, optional: true

  validates :transaction_type, :security_id, :quantity, :price, presence: true

  TYPES = [
    'Buy',
    'Sell'
  ]

  before_save :calculate_amount

  def calculate_amount
    self.amount = (self.price * self.quantity) + self.fee + self.other
  end
end
