include FactoryBot::Syntax::Methods

create(:currency)
security_1 = create(:security)
security_2 = create(:security)
securities = [security_1, security_2]

account = create(:account, title: 'Test Account')
create_list(:trade, 5, account: account, security: securities[rand(2)], quantity: 10)

account = create(:account, title: 'Test Big Account')
(1..20).each do |count|
  create(:trade, account: account, security: securities[rand(2)], quantity: rand(49) * 2, trade_type: Trade::TYPES[rand(2)], date: Date.today - rand(20))
end
