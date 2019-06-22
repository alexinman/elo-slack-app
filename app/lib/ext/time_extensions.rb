class Time
  def slack_format
    "<!date^#{to_i}^{date_short_pretty} at {time}|#{strftime('%b %d, %Y at %l:%M%p %Z')}>"
  end
end