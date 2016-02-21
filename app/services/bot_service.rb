class BotService
    @endpoint = 'https://api.telegram.org/bot'
    MY_CONFIG = YAML.load_file("#{Rails.root.to_s}/my_secrets.yml")
    @token = MY_CONFIG['token']

    def self.send_message(text, chat_id)

      method = "/sendMessage"
      options = {
        body: {
          chat_id: chat_id,
          text: text
        }
      }

      response = HTTParty.get(@endpoint + @token + method, options)
    end
end
