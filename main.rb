require 'sqlite3'
require 'selenium-webdriver'
require 'net/http'
require 'uri'
require 'nokogiri'
require 'date'

class Reserve_info
    def initialize
        @get_id = 0
        @get_time = 0
        @v1 = "-"
        @v2 = "-"
        @v3 = "-"
        @v4 = "-"
        @v5 = "-"
        @v6 = "-"
        @v7 = "-"
        @v8 = "-"
    end
    attr_accessor :get_id , :get_time , :v1 , :v2 , :v3 , :v4 , :v5 , :v6 , :v7 , :v8

    def insert_db(db)
        db.execute('insert into reserve_info values(?,?,?,?,?,?,?,?,?,?)',@get_id,@get_time,@v1,@v2,@v3,@v4,@v5,@v6,@v7,@v8)
    end

end


caps = Selenium::WebDriver::Remote::Capabilities.chrome("chromeOptions" => {args: ["--headless"]})
driver = Selenium::WebDriver.for :chrome, desired_capabilities: caps

db = SQLite3::Database.new 'jr_reserve_checker.db'
db.execute('select * from get_list;') do |row|
    date = row[3].split('/')
    time = row[4].split(':')
    driver.get 'http://www.jr.cyberstation.ne.jp/vacancy/Vacancy_ns.html'
    select = Selenium::WebDriver::Support::Select.new(driver.find_element(:id, 'month'))
    select.select_by(:value, date[0])
    select = Selenium::WebDriver::Support::Select.new(driver.find_element(:id, 'day'))
    select.select_by(:value, date[1])
    select = Selenium::WebDriver::Support::Select.new(driver.find_element(:id, 'hour'))
    select.select_by(:value, time[0])
    select = Selenium::WebDriver::Support::Select.new(driver.find_element(:id, 'minute'))
    select.select_by(:value, time[1][0]+"0")
    select = Selenium::WebDriver::Support::Select.new(driver.find_element(:id, 'train'))
    select.select_by(:value, row[8])
    driver.find_element(:id, 'dep_stn').send_keys row[6]
    driver.find_element(:id, 'arr_stn').send_keys row[7]
    driver.find_element(:name, 'submit').click
    doc = Nokogiri::HTML driver.page_source.encode("UTF-8")
    p row

    elements = doc.css('body > center:nth-child(3) > table > tbody > tr:nth-child(2) > td > table > tbody > tr > td > center:nth-child(3) > table > tbody > tr:nth-child(n+3):not(:last-child)')
    #puts elements
    elements.each do |element|
        
        if element.first_element_child.text == row[2] then
            info = Reserve_info.new()
            info.get_time = Time.now.to_i
            info.get_id = row[0]
            element.css('td:nth-child(n+4)').each_with_index do |e,i|

                case i
                when 0 
                    info.v1 = e.text
                when 1
                    info.v2 = e.text
                when 2
                    info.v3 = e.text
                when 3
                    info.v4 = e.text
                when 4
                    info.v5 = e.text
                when 5
                    info.v6 = e.text
                when 6
                    info.v7 = e.text
                when 7
                    info.v8 = e.text
                end
                
            end
            info.insert_db(db)
            df = db.execute('SELECT * FROM reserve_info WHERE get_id = ? ORDER BY get_time DESC limit 2 ',row[0])
            for i in 2..9 do
                if df[0][i]!=df[1][i] then
                    puts "取得ID:" + row[0].to_s + "の" + "空席(" + (i-1).to_s + ")に変化がありました。　" + df[1][i] + " → " + df[0][i]
                    
                end
            end
        end
    end

end