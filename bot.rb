require 'slack-ruby-client'
require 'selenium-webdriver'
require 'net/http'
require 'uri'
require 'nokogiri'


caps = Selenium::WebDriver::Remote::Capabilities.chrome("chromeOptions" => {args: ["--headless"]})
driver = Selenium::WebDriver.for :chrome, desired_capabilities: caps


Slack.configure do |conf|
    conf.token = 'token'
end
  
client = Slack::RealTime::Client.new

client.on :hello do
  puts "Successfully connected, welcome '#{client.self.name}' to the '#{client.team.name}' team at https://#{client.team.domain}.slack.com."
end

client.on :message do |data|
  case data.text
  when /http/ then
    client.typing channel: data.channel
    client.message channel: data.channel, text: "url detect"
    driver.get data.text[1..data.text.length-2]
    client.message channel: data.channel, text: driver.title
  when /help/ then
    mes = "JR mm/dd hh:mm kind dep_stn arr_stn\nkind\n1:のぞみ・ひかり・みずほ・さくら・つばめ\n2:こだま\n3:はやぶさ・はやて・やまびこ・なすの・つばさ・こまち\n4:とき・たにがわ・かがやき・はくたか・あさま・つるぎ\n5:在来線"
    client.message channel: data.channel, text: mes

  when /^JR/ then
    dataset = data.text.split(' ')
    date = dataset[1].split('/')
    time = dataset[2].split(':')
    client.typing channel: data.channel
    client.ping
    mes = ""
    driver.get 'http://www.jr.cyberstation.ne.jp/vacancy/Vacancy_ns.html'

    select = Selenium::WebDriver::Support::Select.new(driver.find_element(:id, 'month'))
    select.select_by(:value, date[0])
    select = Selenium::WebDriver::Support::Select.new(driver.find_element(:id, 'day'))
    select.select_by(:value, date[1])
    select = Selenium::WebDriver::Support::Select.new(driver.find_element(:id, 'hour'))
    select.select_by(:value, time[0])
    select = Selenium::WebDriver::Support::Select.new(driver.find_element(:id, 'minute'))
    select.select_by(:value, time[1])
    select = Selenium::WebDriver::Support::Select.new(driver.find_element(:id, 'train'))
    select.select_by(:value, dataset[3])
    driver.find_element(:id, 'dep_stn').send_keys dataset[4]
    driver.find_element(:id, 'arr_stn').send_keys dataset[5]
    driver.find_element(:name, 'submit').click
    doc = Nokogiri::HTML driver.page_source.encode("UTF-8")

    elements = doc.css('body > center:nth-child(3) > table > tbody > tr:nth-child(2) > td > table > tbody > tr > td > center:nth-child(3) > table > tbody > tr:nth-child(n+3):not(:last-child)')
    if elements.length == 0 then
      client.message channel: data.channel, text: "該当する列車が見つからないか、営業時間外(22:30~6:30)です。"
    else
      elements.each_with_index do |element,i|
          element.css('td').each_with_index do |td,i|
              if i==0 then
                  mes += "列車名: " + td
              elsif i==1 then
                  mes += "\n時刻: " + td + " → "
              elsif i==2 then
                  mes += "" + td + "\n"
              else
                  mes += "空席(" + (i-2).to_s  + "):" + td +" "
              end
              
          end
          mes += "\n\n"
      end
      client.message channel: data.channel, text: mes
    end
  end
end


client.start!

