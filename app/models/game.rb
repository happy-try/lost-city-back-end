class Game
  CITIES = [
    { name: '亚马逊雨林', color: '#008000' },
    { name: '喜马拉雅山', color: '#b74040' },
    { name: '撒哈拉沙漠', color: '#b5aa45' },
    { name: '西伯利亚', color: '#8f76de' },
    { name: '金字塔', color: '#03a9f4' },
  ]

  attr_accessor :room
  attr_accessor :cities, :cities_status
  attr_accessor :player_ping, :player_pong, :players
  attr_accessor :player_ping_status, :player_pong_status
  attr_accessor :leave_cards
  attr_accessor :runing, :finished

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
    if !@players.include?(player)
      @players << player

      room_key = "room:#{@room}"
      Rails.cache.write(room_key, self)
    end
  end

  def player_ready?
    Array(@players).length == 2
  end

  def setup!
    # 初始化卡牌
    @cities = CITIES
    cards = Card.init_cards(@cities)

    @player_ping = @players[0]
    @player_pong = @players[1]

    # 每人8张手牌
    player_ping_in_hands = cards.pop(8)
    player_pong_in_hands = cards.pop(8)

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

    room_key = "room:#{@room}"
    Rails.cache.write(room_key, self)
  end

  private
  def generate_rand
    SecureRandom.urlsafe_base64(6)
  end

  class << self
    def fetch(room)
      room_key = "room:#{room}"
      Rails.cache.fetch(room_key) do
        new(room)
      end
    end

    def update(room, game)
      room_key = "room:#{room}"
      Rails.cache.write(room_key, game)
    end

  end
end
