require 'socksify'
require 'socksify/http'
require 'telegram/bot'
require 'nokogiri'
require_relative 'faraday'
NINA_STICKER = 'CAADAgADWwADR6pIA_YeZRDKDLd7Ag'
HOROSH_STICKER = 'CAADAgADQAADR6pIA-gUF1CgDVpoAg'
EBANINA_STICKER_PACK = 'EbaninaFromPolina'
TOKEN = ENV.fetch('token')
PROXY = ENV.fetch('proxy')
CHGK_QUESTION_URL = 'https://db.chgk.info/xml/random/from_2012-01-01/limit1'

def nina_sticker(bot)
  @time = Time.now + Random.rand(4600..7600)
  begin
    loop do
    sleep 1200
    p @time
    if Time.now.hour < 24 && Time.now.hour > 8 && Time.now > @time
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
      when '/randomadmin@the_polina_bot'
        admins = bot.api.get_chat_administrators(chat_id: message.chat.id)
        number = admins['result'].count
        user = admins['result'][Random.rand(number)]
        bot.api.send_message(chat_id: message.chat.id, text: "Теперь водит @#{user['user']['username'] || user['user']['firstname']}")
      when '/horosh@the_polina_bot'
        bot.api.send_sticker(chat_id: message.chat.id, sticker: HOROSH_STICKER)
      when '/marry@the_polina_bot'
        bot.api.send_message(chat_id: message.chat.id, text: "Профорк, долго еще Ане в девках ходить?")
      when '/reaction@the_polina_bot'
        stickers = bot.api.get_sticker_set(name: EBANINA_STICKER_PACK)['result']['stickers']
        bot.api.send_sticker(chat_id: message.chat.id, sticker: stickers.sample['file_id'])
      when '/question@the_polina_bot'
        uri = URI(CHGK_QUESTION_URL)
        request = Net::HTTP.get(uri)
        question = Nokogiri::XML(request).at_xpath('//Question').content
        answer = Nokogiri::XML(request).at_xpath('//Answer').content
        comments = Nokogiri::XML(request).at_xpath('//Comments').content
        bot.api.send_message(chat_id: message.chat.id, text: question)
        sleep 60
        bot.api.send_message(chat_id: message.chat.id, text: "#{answer}(#{comments}) (с) http://db.chgk.info")
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
