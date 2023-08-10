class GainLoss < ApplicationRecord
  belongs_to :account
  belongs_to :security
  belongs_to :trade
end
