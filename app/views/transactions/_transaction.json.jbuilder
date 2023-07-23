json.extract! transaction, :id, :date, :account_id, :security_id, :price, :quantity, :fee, :other, :amount, :security_balance, :cash_balance, :transaction_type, :created_at, :updated_at
json.url transaction_url(transaction, format: :json)
