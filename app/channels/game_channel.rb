# frozen_string_literal: true

class GameChannel < ApplicationCable::Channel
  include ActiveSupport::Rescuable

  rescue_from Errors::Base do |e|
    broadcast(
      type: :fetch_current,
      error_code: e.code,
      error_msg: e.message
    )
  end

  rescue_from Errors::GameOver do |e|
    broadcast(type: :game_over)
  end

  def subscribed
    p "subscribed: #{params}"
    stream_from "room_#{params[:room]}_#{params[:player]}"
  end

  # 加入房间，如果人满，则开始
  def into_room
    control do
      set_instance

      raise Errors::Base.new('房间已经满了，无法进入') unless @game.player_can_in?(@player)

      # 第一次凑够2个人，需要进行初始化。
      # 如果是重新进入的，则直接获取数据即可。
      # 通过 runing? 来判断是否需要进行初始化。
      if @game.runing?
        @game.players.each { |one| send_current(one) }
        return
      end

      # 进行初始化
      @game.set_player(@player)

      # 添加用户之后，如果这个时候刚好2人
      if @game.player_ready?
        # 初始化
        @game.setup
        @game.set_next_action(:player_ping, :push_card)
        @game.save!

        @game.players.each { |one| send_current(one) }
      else
        broadcast(type: :waitting)
      end
    end
  end

  # 下牌
  # room: 房间标记
  # player: 哪个用户
  # card_id: 卡牌的id
  # throw_away: true / false, 是否丢弃
  def push_card(data)
    control do
      set_instance

      raise Errors::Game if @game.finished
      @game.check_next_action(@current_player, :push_card)

      # 找出当前想要打出的牌
      hand_cards = @current_player_status[:hand_cards]
      using_card = hand_cards.find { |card| card.id == data['card_id'] }
      raise Errors::Base.new('请选择一张手牌') if using_card.blank?

      # 找出该牌对应的城市
      # {:player_ping=>[], :player_pong=>[], :recycle_bin=>[]}
      city_status = @game.cities_status[using_card.city]

      # 判断是否是想丢弃 还是投资进去。
      if data['throw_away']
        city_status[:recycle_bin].push(using_card)
      else
        # 开始进行投资
        city_last_card = city_status[@current_player].last

        # 没下过牌，则可以下
        if city_last_card.blank?
          city_status[@current_player].push(using_card)
        else
          # 如果是投资卡，上一张卡只能是投资卡
          if using_card.investment?
            if city_last_card.investment?
              city_status[@current_player].push(using_card)
            else
              raise Errors::Base.new('该投资卡无法下')
            end
          else
            # 如果是普通牌，比较大小
            if using_card.value > city_last_card.value
              city_status[@current_player].push(using_card)
            else
              raise Errors::Base.new('点数比上一张小，无法下')
            end
          end
        end
      end

      # 正式从手牌移除
      hand_cards.reject! { |card| card.id == data['card_id'] }
      @game.set_next_action(@current_player, :pick_card)

      @game.save!

      @game.players.each do |one|
        send_current(one)
      end
    end
  end

  # 从弃牌堆里 / 剩余的牌堆里 拿一张牌
  def pick_card(data)
    control do
      set_instance

      raise Errors::Game if @game.finished
      @game.check_next_action(@current_player, :pick_card)

      # 从城市堆取回一张
      if data['if_from_city']
        city_status = @game.cities_status[data['city']]
        current_card = city_status[:recycle_bin].pop

        raise Errors::Base.new('无牌可取') if current_card.blank?

        @current_player_status[:hand_cards].push(current_card)
      else
        # 从剩余的堆取回一张
        current_card = @game.leave_cards.pop

        if @game.leave_cards.blank?
          @game.finished = true
          @game.save!

          raise Errors::Game
        end

        @current_player_status[:hand_cards].push(current_card)
      end

      if @current_player == :player_ping
        @game.set_next_action(:player_pong, :push_card)
      else
        @game.set_next_action(:player_ping, :push_card)
      end

      @game.save!

      @game.players.each do |one|
        send_current(one)
      end
    end
  end

  private

  def set_instance
    @room = params['room']
    @player = params['player']
    @game = Game.fetch(@room)

    if @player == @game.player_ping
      @current_player_status = @game.player_ping_status
      @current_player = :player_ping
    else
      @current_player_status = @game.player_pong_status
      @current_player = :player_pong
    end
  end

  # 指定某个选手发送
  def send_current(player, options = {})
    current_player_status = if player == @game.player_ping
                              @game.player_ping_status
                            else
                              @game.player_pong_status
                            end

    data = {
      type: :fetch_current,
      players: @game.players,
      cities: @game.cities,
      cities_status: @game.cities_status,
      hand_cards: current_player_status[:hand_cards].sort_by { |c| [c.city, c.value] },
      leave_count: @game.leave_cards.count,
      next_player: @game.next_player,
      next_action: @game.next_action
    }.merge(options)

    ActionCable.server.broadcast(
      "room_#{@room}_#{player}",
      data
    )
  end

  # 下发给用户的数据
  def broadcast(data)
    ActionCable.server.broadcast("room_#{@room}_#{@player}", data)
  end

  def control
    yield
  rescue => e
    rescue_with_handler(e) || raise
  end
end
