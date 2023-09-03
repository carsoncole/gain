module ApplicationHelper
  include Pagy::Frontend

  def nice_date(date)
    date.strftime('%Y-%b-%d')
  end

  def irs_date(date)
    date.strftime('%b %d, %Y')
  end

  def description_of_property(trade)
    "#{trade.quantity.abs.to_s} sh #{trade.security.name}"
  end

end
