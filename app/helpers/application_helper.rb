module ApplicationHelper
  include Pagy::Frontend

  def nice_date(date)
    date.strftime('%Y-%b-%d')
  end

  def irs_date(date)
    date.strftime('%b %d, %Y')
  end

  def description_of_property(gain_loss)
    "#{gain_loss.quantity.abs.to_s} sh #{gain_loss.security.name}"
  end

end
