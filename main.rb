require 'socksify'
require 'socksify/http'
require 'telegram/bot'
NINA_STICKER = 'CAADAgADWwADR6pIA_YeZRDKDLd7Ag'
HOROSH_STICKER = 'CAADAgADQAADR6pIA-gUF1CgDVpoAg'
TOKEN = ENV.fetch('token')
PROXY = ENV.fetch('proxy')

module Faraday
  class Adapter
    class NetHttp
      def net_http_connection(env)
        proxy = {uri: PROXY,
                #  user: login,
                #  password: password,
                 socks: true}
        if proxy
          if proxy[:socks]
            env[:ssl] = {verify: true}
            sock_proxy(proxy)
          else
            env[:ssl] = {verify: false}
            http_proxy(proxy)
          end
        else
          Net::HTTP
        end.new(env[:url].host, env[:url].port)
      end

      private

      def sock_proxy(proxy)
        proxy_uri = URI.parse(proxy[:uri])
        TCPSocket.socks_username = proxy[:user] if proxy[:user]
        TCPSocket.socks_password = proxy[:password] if proxy[:password]
        Net::HTTP::SOCKSProxy(proxy_uri.host, proxy_uri.port)
      end

      def http_proxy(proxy)
        proxy_uri = URI.parse(proxy[:uri])
        Net::HTTP::Proxy(proxy_uri.host,
                         proxy_uri.port,
                         proxy_uri.user,
                         proxy_uri.password)
      end
    end
  end
end

begin
  Telegram::Bot::Client.run(TOKEN) do |bot|
    bot.listen do |message|
      p message
      case message.text
      when '/randomadmin@the_polina_bot'
        admins = bot.api.get_chat_administrators(chat_id: message.chat.id)
        number = admins['result'].count
        user = admins['result'][Random.rand(number)]
        bot.api.send_message(chat_id: message.chat.id, text: "Теперь водит @#{user['user']['username'] || user['user']['firstname']}")
      when '/etosamoe@the_polina_bot'
        bot.api.send_sticker(chat_id: message.chat.id, sticker: NINA_STICKER)
      when '/horosh@the_polina_bot'
        bot.api.send_sticker(chat_id: message.chat.id, sticker: HOROSH_STICKER)
      when '/marry@the_polina_bot'
        bot.api.send_message(chat_id: message.chat.id, text: "@ev_geny когда свадьба?")
      end
    end
  end
  rescue
    retry
  end
