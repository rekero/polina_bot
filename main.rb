require 'socksify'
require 'socksify/http'
require 'telegram/bot'
require 'nokogiri'
# require_relative 'faraday'
NINA_STICKER = 'CAADAgADWwADR6pIA_YeZRDKDLd7Ag'
FOR_NINA_STICKER = 'CAADAgAD5wADR6pIA-ss3yCOsEYpAg'
FOR_SASHA_STICKER = 'CAADAgADbgADR6pIA0pkDbdQ0CX_Ag'
HOROSH_STICKER = 'CAADAgADQAADR6pIA-gUF1CgDVpoAg'
EBANINA_STICKER_PACK = 'EbaninaFromPolina'
TOKEN = ENV.fetch('token')
PROXY = ENV.fetch('proxy')
CHGK_QUESTION_URL = 'https://db.chgk.info/xml/random/from_2012-01-01/limit1/types1'
CHGK_IMAGE_URL = 'https://db.chgk.info/images/db/'
CHGK_COPYRIGHT_URL = 'http://db.chgk.info'
PIC_TEXT = 'pic: '

def nina_sticker(bot)
  @time = Time.now + Random.rand(4600..7600)
  begin
    loop do
      sleep 1200
      p @time
      if Time.now.hour < 18 && Time.now.hour > 5 && Time.now > @time
        bot.api.send_sticker(chat_id: -1001098597975, sticker: NINA_STICKER)
        @time = Time.now + Random.rand(4600..7600)
      end
    end
  rescue => e
    p e.message
    retry
  end
end

def work(bot)
  begin
    bot.listen do |message|
      p message
      case message.text
      when '/horosh@the_polina_bot'
        bot.api.send_sticker(chat_id: message.chat.id, sticker: HOROSH_STICKER)
      when '/reaction@the_polina_bot'
        stickers = bot.api.get_sticker_set(name: EBANINA_STICKER_PACK)['result']['stickers']
        bot.api.send_sticker(chat_id: message.chat.id, sticker: stickers.sample['file_id'])
      when '/est_cho@the_polina_bot'
        bot.api.send_message(chat_id: message.chat.id, text: "#чёпосмотреть #чёпочитать")
      when '/question@the_polina_bot'
        uri = URI(CHGK_QUESTION_URL)
        request = Net::HTTP.get(uri)
        question = Nokogiri::XML(request).at_xpath('//Question').content
        answer = Nokogiri::XML(request).at_xpath('//Answer').content
        comments = Nokogiri::XML(request).at_xpath('//Comments').content
        date = Nokogiri::XML(request).at_xpath('//tourPlayedAt').content
        authors = Nokogiri::XML(request).at_xpath('//Authors').content
        criteria = Nokogiri::XML(request).at_xpath('//PassCriteria').content
        if question.include?(PIC_TEXT)
          question.gsub!(PIC_TEXT, CHGK_IMAGE_URL)
        end
        if authors.include?('Ершов')
          bot.api.send_message(chat_id: message.chat.id, text: "Я спас вас от вопроса Ершова")
        else
          bot.api.send_message(chat_id: message.chat.id, text: "#{question} #{date}")
          sleep 60
          bot.api.send_message(chat_id: message.chat.id, text: "#{answer}(#{criteria})(#{comments}) (с) #{CHGK_COPYRIGHT_URL}")
        end
      end
    end
  rescue => e
    p e.message
    retry
  end
end


begin
  Telegram::Bot::Client.run(TOKEN) do |bot|
    p 'start'
    t1 = Thread.new{nina_sticker(bot)}
    t2 = Thread.new{work(bot)}
    t1.join
    t2.join
  end
end
