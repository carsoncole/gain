json.extract! trade, :id, :date, :account_id, :security_id, :price, :quantity, :fee, :other, :amount, :security_balance, :trade_type, :created_at, :updated_at
json.url trade_url(trade, format: :json)
