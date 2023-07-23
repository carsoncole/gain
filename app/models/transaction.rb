class Transaction < ApplicationRecord
  belongs_to :account
  belongs_to :security, optional: true

  validates :transaction_type, presence: true

  TYPES = [
    'Buy',
    'Sell'
  ]
end
