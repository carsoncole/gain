module ApplicationHelper
  include Pagy::Frontend

  def nice_date(date)
    date.strftime('%Y-%b-%d')
  end

  def irs_date(date)
    date.strftime('%b %d, %Y')
  end

  def description_of_property(gain_loss)
    "#{number_with_delimiter(gain_loss.quantity.abs, precision: 5, strip_insignificant_zeros: true)} sh #{gain_loss.security.name}"
  end

end
