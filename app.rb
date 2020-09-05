require "holiday_japan"
require "selenium-webdriver"
require "slack/incoming/webhooks"
require "dotenv"

Dotenv.load

puts("execute process")

# selenium instance
options = Selenium::WebDriver::Chrome::Options.new(args: ["--headless"])
driver = Selenium::WebDriver.for(:chrome, options: options)
driver.manage.timeouts.implicit_wait = 15

# slack instance
slack = Slack::Incoming::Webhooks.new(ENV["SLACK_WEBHOOK_URL"])

# TODO：class化して綺麗にする？
def work_day?(today)
  !(today.sunday? && today.saturday? && HolidayJapan.check(today))
end


# 土日・祝日は実行しない
unless work_day?(Date.today)
  puts("Today is holiday")
  return
end

# king of timeのページにログイン
driver.get(ENV["URL"])
driver.find_element(:id, "login_id").send_keys(ENV["ID"])
driver.find_element(:id, "login_password").send_keys(ENV["PASS"])
driver.find_element(:id, "login_button").click

# 対象の勤怠情報を取り出す

# heroku schedulerで指定時間に走らせる(出勤12時, 退勤21:30時)
# TODO：実行時間と密な感じ回避できない？
case Time.now.hour
when 12 # 出勤
  selector = "div.htBlock-adjastableTableF_inner > table > tbody > tr:nth-child(#{Date.today.day}) > td:nth-child(7) > p"
when 21 # 退勤
  selector = "div.htBlock-adjastableTableF_inner > table > tbody > tr:nth-child(#{Date.today.day}) > td:nth-child(8) > p"
end

stamp_time = driver.find_element(:css, selector).text

# 打刻してないならslack通知
if stamp_time.empty?
  puts("post message to slack")
  slack.post("Stamp time card!")
end


driver.quit
puts("process end")
