# time_card_notifier

## なにこれ
勤怠の入れ忘れを通知するやつ

## setup

### for local

```bash
# webdriverのインストール
`brew cask install webdriver`

# .env配置
```

### for heroku


```bash
# buildpacksを追加
- 標準のruby_buildpack
- https://github.com/heroku/heroku-buildpack-chromedriver.git
- https://github.com/heroku/heroku-buildpack-google-chrome.git

# webdriverのpathを追加
- `heroku config:set GOOGLE_CHROME_BIN=/app/.apt/opt/google/chrome/chrome`
- `heroku config:set GOOGLE_CHROME_SHIM=/app/.apt/opt/google/chrome/chrome`

# herokuのtimezone変更(heroku cli)
`heroku config:add TZ=Asia/Tokyo --app app_name` or web：configversに TZ = Asia/Tokyo
```

## memo

- スクリプト実行
  - `bundle exec ruby app.rb`