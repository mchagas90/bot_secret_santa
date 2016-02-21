class SecretSantaController < ApplicationController
  skip_before_filter :verify_authenticity_token, :only => [:webhook]
  before_filter :is_chat?, :only => [:webhook]

  def webhook
    Rails.logger.info(params)

    if should_create_secret_santa_event?
      event = SecretSantaEvent.new
      event.id_chat = normalized_params[:id_chat]
      event.title = normalized_params[:chat_title]
      event.save
    end

    if commands.has_key?(normalized_params[:message_text])
      send(commands[normalized_params[:message_text]])
    elsif create_wish_list?
      participant = get_participant_by_id_telegram(
        normalized_params[:participant_telegram_id],
        normalized_params[:id_chat]
      )

      Participant.update(participant.id, wish_list: normalized_params[:message_text])
    else
      render :text => '{}', :status => 403
    end
    render :text => '{}', :status => 200
  end

  private
  def commands
    {
      "DENTRO"=> "set_participant",
      "FORA"=> "remove_participant",
      "SORTEIO"=> "raffle"
    }.with_indifferent_access
  end

  def normalized_params
    {
      message_text: params["message"]["text"],
      id_chat: params["message"]["chat"]["id"],
      chat_title: params["message"]["chat"]["title"],
      participant_name: "#{params['message']['from']['first_name']} #{params['message']['from']['last_name']}",
      participant_telegram_id: params["message"]["from"]["id"],
      chat_type: params["message"]["chat"]["type"]
    }
  end

  def should_create_secret_santa_event?
    ! SecretSantaEvent.exists?(id_chat: normalized_params[:id_chat])
  end

  def remove_participant
    participant = get_participant_by_id_telegram(
      normalized_params[:participant_telegram_id],
      normalized_params[:id_chat]
    )

    Participant.update(participant.id, participating: false)
  end

  def send_message(message_text, chat_id)
    BotService.send_message(message_text, chat_id)
  end

  def is_chat?
    unless normalized_params[:chat_type] == "group"
      render :text => '{}', :status => 403
    end
  end

  def set_participant
    participant = get_participant_by_id_telegram(
        normalized_params[:participant_telegram_id],
        normalized_params[:id_chat]
      )

    if participant.present?
      participant.participating = true
    else
      participant = Participant.new
      participant.name = normalized_params[:participant_name]
      participant.participating = true
      participant.id_telegram = normalized_params[:participant_telegram_id]
      participant.secret_santa_event_id = get_event.id_chat
    end
    participant.save
  end

  def get_event
    SecretSantaEvent.where(id_chat: normalized_params[:id_chat]).first
  end

  def get_all_active_participants
    Participant.where(
      secret_santa_event_id: normalized_params[:id_chat],
      participating: true
    ).order("RANDOM()")
  end

  def raffle
    @participants_to_raffle = get_all_active_participants
    if @participants_to_raffle.size >= 2
      magic
    end
    @hash.each do |id, message| send_message(message, id) end
  end

  def magic
    @hash = {}
    @participants_to_raffle.each_with_index {|participant, index|
      next_participant = @participants_to_raffle[index+1]
      if next_participant.nil?
        @hash[participant.id_telegram] = "#{@participants_to_raffle.first.name}, #{@participants_to_raffle.first.wish_list}"
      else
        @hash[participant.id_telegram] = "#{next_participant.name}, #{next_participant.wish_list}"
      end
    }
  end

  def create_wish_list?
    normalized_params[:message_text].start_with?("PRESENTE")
  end

  def get_participant_by_id_telegram(id_telegram, secret_santa_event_id)
    Participant.where(
      id_telegram: id_telegram,
      secret_santa_event_id: secret_santa_event_id
    ).first
  end

end
