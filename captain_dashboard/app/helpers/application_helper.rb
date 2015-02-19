module ApplicationHelper
  def format_datetime(datetime)
    if datetime
      datetime.strftime("%Y-%m-%d %H:%M")
    else
      ''
    end
  end
end
