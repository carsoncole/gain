class User < ApplicationRecord
  include Clearance::User

  has_many :accounts, dependent: :destroy
  has_many :currencies, dependent: :destroy
  has_many :securities, dependent: :destroy
end
