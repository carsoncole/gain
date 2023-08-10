include FactoryBot::Syntax::Methods

create(:currency)
security = create(:security)

account = create(:account, title: 'Test Account')
create_list(:trade, 5, account: account, security: security, quantity: 10)

account = create(:account, title: 'Test Big Account')
(1..20).each do |count|
  create(:trade, account: account, security: security, quantity: rand(49) * 2, trade_type: Trade::TYPES[rand(2)])
end
