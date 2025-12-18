require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)
require 'socksify'
require 'socksify/http'
require 'telegram/bot'
require 'nokogiri'
require 'vkontakte_api'
require 'openssl'
require 'dotenv'
require 'date'
Dotenv.load
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
# require_relative 'faraday'
NINA_STICKER = 'CAADAgADWwADR6pIA_YeZRDKDLd7Ag'
FOR_NINA_STICKER = 'CAADAgAD5wADR6pIA-ss3yCOsEYpAg'
NEW_NINA_STICKER = 'CAACAgIAAx0CSoiGYwACAg1iXT46RiFZu9ZC4-8-FRuFajh6PgACJhQAAkHFIUpMI1D7UR-ORiQE'
FOR_SASHA_STICKER = 'CAADAgADbgADR6pIA0pkDbdQ0CX_Ag'
HOROSH_STICKER = 'CAADAgADQAADR6pIA-gUF1CgDVpoAg'
SUN_STICKER = 'CAADAgADtAADIo4KAAEKpIfc9R7N7wI'
EBANINA_STICKER_PACK = 'EbaninaFromPolina'
TOKEN = ENV.fetch('token')
PROXY = ENV.fetch('proxy')
VK_TOKEN = ENV.fetch('vk_token')
CHGK_QUESTION_URL = "https://db.chgk.info/xml/random/from_#{Date.today.year - 10}-01-01/limit1/types1"
CHGK_IMAGE_URL = 'https://db.chgk.info/images/db/'
CHGK_COPYRIGHT_URL = 'http://db.chgk.net'
PIC_TEXT = 'pic: '
DUDKIN = 110064
ZAPAS_URL = 'https://gotquestions.online/'
ZAPAS_QUESTION_URL = 'https://gotquestions.online/question/'

def good_boy(bot)
  @time = Time.now + Random.rand(146000..176000)
  begin
    loop do
      sleep 50000
      p @time
      if Time.now > @time
        bot.api.send_message(chat_id: -1001098597975, text: "Вы хорошие")
        bot.api.send_sticker(chat_id: -1001098597975, sticker: SUN_STICKER)
        @time = Time.now + Random.rand(146000..256000)
      end
    end
  rescue => e
    p e.message
    retry
  end
end

def nina_sticker(bot)
  @time = Time.now + Random.rand(4600..7600)
  begin
    loop do
      sleep 1200
      p @time
      if Time.now.hour < 18 && Time.now.hour > 5 && Time.now > @time
        bot.api.send_sticker(chat_id: -1001098597975, sticker: NEW_NINA_STICKER)
        @time = Time.now + Random.rand(14600..17600)
      end
    end
  rescue => e
    p e.message
    retry
  end
end

def work(bot)
  users = {}
  begin
    bot.listen do |message|
      p message
      case message.text.to_s.split("@").first
      when '/stats'
	bot.api.send_message(chat_id: message.chat.id, text: users.map { |k, v| "#{k} : #{v}" }.join(';'))
      when '/horosh'
        bot.api.send_sticker(chat_id: message.chat.id, sticker: HOROSH_STICKER)
      when '/reaction'
        stickers = bot.api.get_sticker_set(name: EBANINA_STICKER_PACK)['result']['stickers']
        bot.api.send_sticker(chat_id: message.chat.id, sticker: stickers.sample['file_id'])
      when '/est_cho'
        bot.api.send_message(chat_id: message.chat.id, text: "#чёпосмотреть #чёпочитать")
      when '/dudkin'
        vk = VkontakteApi::Client.new
        jokes = vk.wall.get(owner_id: DUDKIN, count: 100, filter: 'owner', access_token: VK_TOKEN, v: '5.103', offset: Random.rand(0..9)*100)[:items]
        bot.api.send_message(chat_id: message.chat.id, text: jokes.sample[:text])
      when '/zapas'
        question, answer = parse_zapas_question
        bot.api.send_message(chat_id: message.chat.id, text: question)
        sleep 65
        bot.api.send_message(chat_id: message.chat.id, text: answer)
      when '/question'
	if message.chat.username == 'vprsk'
          name = message.from.username || "#{message.from.first_name} #{message.from.last_name}"
          unless  users[name].nil?
            users[name] = users[name]+1
          else
            users[name] = 0
          end
          question, answer, authors = parse_question
          if authors.include?('Ершов')
	    bot.api.send_message(chat_id: message.chat.id, text: "Я спас вас от вопроса Ершова")
          else
            bot.api.send_message(chat_id: message.chat.id, text: question)
            sleep 65
            bot.api.send_message(chat_id: message.chat.id, text: answer)
          end
        end
      end
    end
  rescue => e
    p e.message
    retry
  end
end

def parse_question
  uri = URI(CHGK_QUESTION_URL)
  request = Net::HTTP.get(uri)
  question = Nokogiri::XML(request).at_xpath('//Question').content
  answer = Nokogiri::XML(request).at_xpath('//Answer').content
  comments = Nokogiri::XML(request).at_xpath('//Comments').content
  date = Nokogiri::XML(request).at_xpath('//tourPlayedAt').content
  authors = Nokogiri::XML(request).at_xpath('//Authors').content
  criteria = Nokogiri::XML(request).at_xpath('//PassCriteria').content
  tour = Nokogiri::XML(request).at_xpath('//ParentTextId').content
  number = Nokogiri::XML(request).at_xpath('//Number').content
  return "#{clean_text(question)} #{date}", "#{clean_text(answer)}(#{criteria})(#{clean_text(comments)}) #{CHGK_COPYRIGHT_URL}/question/#{tour}/#{number}", authors
end

def parse_zapas_question
  uri = URI("#{ZAPAS_QUESTION_URL}#{rand(1..410000)}")
  p uri.to_s
  request = Net::HTTP.get(uri)
  result = Nokogiri::HTML.parse(request).css("script").detect do |element|
    element.content.include?('nezachet')
  end&.content&.delete('\\')
  return uri.to_s, "" if result.nil?

  question = result.slice(result.index('text"')..result.index('","razdatkaText')+1)[7..-3]
  answer = result.slice(result.index('answer"')..result.index('","answerPic'))[9..-3]
  zachet = result.slice(result.index('zachet"')..result.index('nezachet'))[10..-4]
  comment = result.slice(result.index('comment"')..result.index('note'))[10..-4]
  razdatka = result.slice(result.index('razdatkaPic"')..result.index('audio'))[15..-4]
  return "#{question} #{razdatka == '' ? '' : ZAPAS_URL + razdatka}", "#{answer} (#{zachet})(#{comment}) #{ZAPAS_URL}"
end

def clean_text(text)
  parsed_text = Nokogiri::HTML.parse text
  parsed_text.text.gsub(PIC_TEXT, CHGK_IMAGE_URL) unless text.include?('imgur')
end


begin
  Telegram::Bot::Client.run(TOKEN) do |bot|
    p 'start'
    t1 = Thread.new{nina_sticker(bot)}
    t2 = Thread.new{work(bot)}
    t3 = Thread.new{good_boy(bot)}
    t1.join
    t2.join
    t3.join
  end
end
