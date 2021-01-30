# frozen_string_literal: true

class Game
  CITIES = [
    { name: '亚马逊雨林', color: '#008000' },
    { name: '喜马拉雅山', color: '#b74040' },
    { name: '撒哈拉沙漠', color: '#b5aa45' },
    { name: '西伯利亚', color: '#8f76de' },
    { name: '金字塔', color: '#03a9f4' },
    { name: '盘贝古城', color: '#795548' }
  ].freeze

  attr_accessor :room
  attr_accessor :cities, :cities_status
  attr_accessor :player_ping, :player_pong, :players
  attr_accessor :player_ping_status, :player_pong_status
  attr_accessor :leave_cards
  attr_accessor :runing, :finished
  attr_accessor :next_player, :next_action

  def initialize(room)
    @room = room
    @players = []
    @runing = false
    @finished = false
  end

  def player_can_in?(player)
    if @players.length >= 2
      @players.include?(player)
    else
      true
    end
  end

  def runing?
    @runing
  end

  def set_player(player)
    unless @players.include?(player)
      @players << player

      room_key = "room:#{@room}"
      Rails.cache.write(room_key, self)
    end
  end

  def player_ready?
    Array(@players).length == 2
  end

  def setup
    # 初始化卡牌
    @cities = CITIES
    cards = Card.init_cards(@cities)

    @player_ping = @players[0]
    @player_pong = @players[1]

    # 每人8张手牌
    player_ping_in_hands = cards.shift(4) + cards.pop(4)
    player_pong_in_hands = cards.shift(4) + cards.pop(4)

    # 每个城市的当前状态
    @cities_status = {}
    @cities.each do |city|
      @cities_status[city[:name]] = {
        player_ping: [],  # 选手A下的牌
        player_pong: [],  # 选手B下的牌
        recycle_bin: []   # 回收队列的牌
      }
    end

    @player_ping_status = {
      name: @player_ping,
      hand_cards: player_ping_in_hands  # 手牌
    }

    @player_pong_status = {
      name: @player_pong,
      hand_cards: player_pong_in_hands  # 手牌
    }

    @leave_cards = cards # 牌堆剩余的牌
    @runing = true
  end

  def set_next_action(player, action)
    @next_player = player
    @next_action = action
  end

  def check_next_action(player, action)
    action_mapping = {
      pick_card: '从弃牌堆 / 剩余牌堆选择一张',
      push_card: '从手牌打出一张牌'
    }

    raise Errors::Base.new('等待对手操作') if @next_player != player
    raise Errors::Base.new(action_mapping[@next_action]) if @next_action != action
  end

  def save!
    room_key = "room:#{@room}"
    Rails.cache.write(room_key, self, expires_in: 2.days)
  end

  class << self
    def fetch(room)
      room_key = "room:#{room}"
      Rails.cache.fetch(room_key, expires_in: 2.days) do
        new(room)
      end
    end

    def reset(room)
      room_key = "room:#{room}"
      old_game = fetch(room)

      game = new(room)
      game.set_player(old_game.player_ping)
      game.set_player(old_game.player_pong)

      game.setup
      game.set_next_action(:player_ping, :push_card)

      Rails.cache.write(room_key, game, expires_in: 2.days)
      game
    end
  end
end
