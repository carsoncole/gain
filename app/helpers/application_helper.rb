module ApplicationHelper
  include Pagy::Frontend

  def nice_date(date)
    date.strftime('%Y-%b-%d')
  end

end
