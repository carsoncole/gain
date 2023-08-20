include FactoryBot::Syntax::Methods


user = User.first
currency = create(:currency, user: user)
security_1 = create(:security, user: user, currency: currency)
security_2 = create(:security, user: user, currency: currency)
securities = [security_1, security_2]

account = create(:account, title: 'Test Account', user: user, currency: currency)
create_list(:trade, 5, account: account, security: securities[rand(2)], quantity: 10)

account = create(:account, title: 'Test Big Account', user: user, currency: currency)
(1..20).each do |count|
  create(:trade, account: account, security: securities[rand(2)], quantity: rand(49) * 2, trade_type: Trade::TYPES[rand(2)], date: Date.today - rand(20))
end
