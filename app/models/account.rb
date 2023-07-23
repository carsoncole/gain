class Account < ApplicationRecord
  belongs_to :currency
  has_many :transactions, dependent: :destroy
  validates :title, :number, presence: true
end
