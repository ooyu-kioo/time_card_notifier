require "holiday_japan"
require "selenium-webdriver"
require "slack/incoming/webhooks"
require "dotenv"

Dotenv.load

puts("execute process apply_time_stamps.rb")

# selenium instance
options = Selenium::WebDriver::Chrome::Options.new(args: ["--headless"])
driver = Selenium::WebDriver.for(:chrome, options: options)
driver.manage.timeouts.implicit_wait = 15

# slack instance
slack = Slack::Incoming::Webhooks.new(ENV["SLACK_WEBHOOK_URL"])

# TODO：切り出す
def work_day?(today)
  !(today.sunday? || today.saturday? || HolidayJapan.check(today))
end
def end_of_month?(day)
  Date.new(Time.now.year, Time.now.month, -1).day == day
end
def can_execute?(today)
  work_day?(today) && end_of_month?(today.day)
end

# 土日・祝日・月末以外は実行しない
unless can_execute?(Date.today)
  puts("Today is holiday or not end of month")
  return
end

# king of timeのページにログイン
driver.get(ENV["URL"])
driver.find_element(:id, "login_id").send_keys(ENV["ID"])
driver.find_element(:id, "login_password").send_keys(ENV["PASS"])
driver.find_element(:id, "login_button").click

# 月末の勤怠申請を行う
selector = "body > div > div.htBlock-mainContents > div > div.htBlock-toolbar.specific-toolbar > div:nth-child(1) > form:nth-child(1) > span"
error_message = driver.find_elements(:css, selector).size

if error_message > 0
  slack.post("There is error, can't apply time card!")
  return
end

# 打刻申請
# 申請ボタンであることを確認してから押したいけど、うまいこと押せないのでそのままクリックする
driver.find_element(:id, "button_06").click
driver.find_element(:id, "button_06").click

# 申請できたかの確認
selector = "body > div > div.htBlock-mainContents > div > div.htBlock-toolbar.specific-toolbar > div:nth-child(1) > form:nth-child(1) > span"
complete_text = "There is an unapproved Confirmation request. You can't edit Schedules and Time record data." # headlessだとなぜか英語表記になる

element = driver.find_elements(:css, selector)

if element.size > 0 && element[0].text == complete_text
  slack.post("Sent an approve request!!!!!!!!!!")
else
  slack.post("Something wrong. check time card!")
end

driver.quit
puts("process end")
