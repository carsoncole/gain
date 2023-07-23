class Account < ApplicationRecord
  belongs_to :currency
  validates :title, :number, presence: true
end
