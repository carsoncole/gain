class Trade < ApplicationRecord
  has_many :gain_losses, dependent: :destroy
  belongs_to :account
  belongs_to :security

  attr_accessor :is_recalc

  validates :date, :trade_type, :security_id, presence: true
  validates :price, :quantity, presence: true, if: -> { trade_type == ['Buy', 'Sell'] }

  scope :buy_sell, -> { where(trade_type: ['Buy', 'Sell'])}
  scope :splits, -> { where(trade_type: 'Split') }

  TYPES = [
    'Buy',
    'Sell',
    'Split',
    'Conversion'
  ]

  # Trade steps
  # calculate_quantity_balances
  # => all trades set balances
  # calculate_gains_and_losses
  # => all trades set initial tax balances, and split trade values
  # => all trades process gains and losses

  after_initialize :set_defaults!
  before_validation :set_sign!, unless: :is_recalc
  before_save :set_amount_or_price!, unless: :is_recalc
  after_save :calculate_quantity_balances!, unless: :is_recalc

  after_destroy :calculate_quantity_balances!

  # after_save :adjust_tax_balances_for_splits!, unless: :is_recalc
  # after_destroy :adjust_tax_balances_for_splits!

  # Update quantity and cost tax balances
  after_commit :calculate_gains_and_losses!, unless: :is_recalc

  # after_commit :offset_trades!, unless: :is_recalc

  def set_defaults!
    self.date ||= Date.today
    self.trade_type ||= 'Buy'
  end

  def set_values!
    related_security_trades.each do |t|
      t.calculate_quantity_balance!

      self.quantity_tax_balance = self.quantity if buy_or_sell?
      self.cost_tax_balance = self.amount * (buy? ? 1 : -1) if buy_or_sell?

      t.is_recalc = true
      t.save if t.changed?
    end
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

  def  buy_sell_split?
    buy? || sell? || split?
  end

  def split?
    trade_type == 'Split'
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

  def calculate_quantity_balance!
    if buy_or_sell?
      self.quantity_balance = prior_quantity_balance + quantity
    elsif split?
      self.quantity_balance = split_new_shares
    end
  end

  def calculate_quantity_balances!
    related_security_trades.each do |t|
      t.calculate_quantity_balance!
      t.is_recalc = true
      t.save if t.changed?
    end
  end

  def set_initial_tax_balances!
    self.quantity_tax_balance = self.quantity if buy_or_sell?
    self.cost_tax_balance = self.amount * (buy? ? 1 : -1) if buy_or_sell?
    adjust_tax_balances_for_splits! if split?
  end

  def adjust_tax_balances_for_splits!
    puts "*"*80
    puts "adjusting for splits"
    puts self.inspect
    trades_to_process = related_security_trades.where("quantity_tax_balance <> 0 AND date < ?", date)
    split_ratio = split_new_shares / quantity_balance
    shares_distributed = 0
    trades_to_process.each do |rst|
      rst.is_recalc = true
      if rst == trades_to_process.last
        rst.quantity_tax_balance = split_new_shares - shares_distributed
      else
        rst.quantity_tax_balance *= split_ratio
        shares_distributed += rst.quantity_tax_balance
      end
      puts "shares distributed"
      puts shares_distributed
      rst.save
    end

  end

  def quantity_balance_needs_updating?
    if quantity_changed? || date_changed?
      true
    else
      false
    end
  end

  def related_security_trades
    security.trades.where("account_id = ?", self.account_id).order(date: :asc, created_at: :asc)
  end

  def related_buy_sell_trades
    security.trades.buy_sell.where("account_id = ?", self.account_id).order(date: :asc, created_at: :asc)
  end

  def related_counter_trades
    if trade_type == 'Buy' || trade_type == 'Split'
      account.trades.buy_sell.where("security_id = ? AND (quantity_tax_balance < 0 AND (date < ? OR ( date = ? AND created_at < ? )))", self.security_id, self.date, self.date, self.created_at ||= Time.now).order(date: :asc, created_at: :asc)
    elsif trade_type == 'Sell' || trade_type == 'Split'
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
    return unless buy_sell_split?
    # reset all balances to initial values
    # related_security_trades.each do |rst|
    #   rst.set_initial_tax_balances!
    #   rst.is_recalc = true
    #   rst.save if rst.changed?
    # end

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


end
