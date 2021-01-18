class GameChannel < ApplicationCable::Channel
  def subscribed
    p params
    stream_from "room_#{params[:room]}_#{params[:player]}"
  end

  # def receive(data)
  #   ActionCable.server.broadcast("room_#{params[:room]}", data)
  # end

  # 创建新的房间
  def create_room(data)
    player = params[:player]
    Room.fetch(player)
  end

  # 加入房间，如果人满，则开始
  def into_room
    room = params['room']
    player = params['player']
    game = Game.fetch(room)

    if game.player_can_in?(player)
      raise '房间已经满了，无法进入'
    end

    # 第一次凑够2个人，需要进行初始化。
    # 如果是重新进入的，则直接获取数据即可。
    # 通过 runing? 来判断是否需要进行初始化。
    if game.runing?
      game[:players].each do |player|
        send_current(game, player)
      end

      return
    end

    # 进行初始化
    game.set_player(player)
    if game.player_ready?
      if game.ready?
        game[:players].each do |player|
          send_current(game, player)
        end
      end
    else
      broadcast(
        type: :waitting,
        error_code: 10002,
        error_msg: '等待其他选手进入'
      )
    end
  end

  def send_current(game, player)
    ActionCable.server.broadcast(
      "room_#{params[:room]}_#{player}",
      type: :fetch_current,
      players: game[:players],
      cities: game[:cities],
      cities_status: game[:cities_status],
      hand_cards: game[player][:hand_cards].sort_by { |c| [c.city, c.value] },
      leave_count: game[:leave_cards].count
    )
  end


  # 获取当前该显示的数据
  # room: 房间标记
  # player: 哪个用户
  # params: {"channel"=>"GameChannel", "room"=>"oWT2-3Bv"}
  # data: {"player"=>"xiaodong", "action"=>"fetch_current"}
  def fetch_current(data)
    room = params['room']
    player = data['player'].to_sym
    game = Game.fetch(room)

    broadcast(
      type: :fetch_current,
      players: game[:players],
      cities: game[:cities],
      cities_status: game[:cities_status],
      hand_cards: game[player][:hand_cards].sort_by { |c| [c.city, c.value] },
      leave_count: game[:leave_cards].count
    )
  end

  # 下牌
  # room: 房间标记
  # player: 哪个用户
  # card_id: 卡牌的id
  # throw_away: true / false, 是否丢弃
  def push_card(data)
    p params
    p data

    room = params['room']
    player = data['player'].to_sym
    game = Game.fetch(room)
    error_code = 1000
    error_msg = ''

    # 找出当前想要打出的牌
    hand_cards = game[player][:hand_cards]
    using_card = hand_cards.find { |card| card.id == data['card_id'] }

    raise '请选择一张手牌' if using_card.blank?

    # 找出该牌对应的城市
    # {:xiaodong=>[], :other=>[], :recycle_bin=>[]}
    city_status = game[:cities_status][using_card.city]

    # 判断是否是想丢弃 还是投资进去。
    if data['throw_away']
      city_status[:recycle_bin].push(using_card)
    else
      # 开始进行投资
      city_last_card = city_status[player].last

      # 没下过牌，则可以下
      if city_last_card.blank?
        city_status[player].push(using_card)
      else
        # 如果是投资卡，上一张卡只能是投资卡
        if using_card.type == 'investment'
          if city_last_card.type == 'investment'
            city_status[player].push(using_card)
          else
            raise '该投资卡无法下'
          end
        else
          # 如果是普通牌，比较大小
          if using_card.value > city_last_card.value
            city_status[player].push(using_card)
          else
            raise '点数比上一张小，无法下'
          end
        end
      end
    end

    # 正式从手牌移除
    hand_cards.reject! { |card| card.id == data['card_id'] }
  rescue => e
    error_code = 10001
    error_msg = e.message
  ensure
    check_and_update(error_code, error_msg, room, game, player)
  end

  # 从弃牌堆里 / 剩余的牌堆里 拿一张牌
  def pick_card(data)
    room = params['room']
    player = data['player'].to_sym
    game = Game.fetch(room)

    error_code = 1000
    error_msg = ''
    finished = false

    # 从城市堆取回一张
    if data['if_from_city']
      city_status = game[:cities_status][data['city']]
      current_card = city_status[:recycle_bin].pop

      if current_card.blank?
        error_code = 10001
        error_msg = '无牌可取'
      else
        game[player][:hand_cards].push(current_card)
      end
    else
      # 从弃牌堆取回一张
      current_card = game[:leave_cards].pop

      if current_card.blank?
        error_code = 10001
        error_msg = '牌组抽完，游戏结束'
        finished = true
      else
        game[player][:hand_cards].push(current_card)
      end
    end

    check_and_update(error_code, error_msg, room, game, player, { finished: finished })
  end

  def check_and_update(error_code, error_msg, room, game, player, options = {})
    if error_code > 10000
      broadcast(
        type: :fetch_current,
        error_code: error_code,
        error_msg: error_msg
      )
    else
      Game.update(room, game)

      data = options.merge(
        type: :fetch_current,
        players: game[:players],
        cities: game[:cities],
        cities_status: game[:cities_status],
        hand_cards: game[player][:hand_cards].sort_by { |c| [c.city, c.value] },
        leave_count: game[:leave_cards].count
      )
      broadcast(data)
    end
  end

  # 下发给用户的数据
  def broadcast(data)
    ActionCable.server.broadcast("room_#{params[:room]}", data)
  end
end
