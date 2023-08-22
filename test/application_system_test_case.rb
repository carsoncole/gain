require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  # Webdrivers::Chromedriver.required_version = "114.0.5735.90" #BUG FIX https://github.com/titusfortner/webdrivers/issues/247 ** The last fix was by fixing webdrivers gem to 5.3.0, so no longer need this line
  driven_by :selenium, using: :chrome, screen_size: [1400, 1400]
end
