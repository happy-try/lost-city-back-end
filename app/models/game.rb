class Game
  CITIES = [
    { name: '亚马逊雨林', color: '#008000' },
    { name: '喜马拉雅山', color: '#b74040' },
    { name: '撒哈拉沙漠', color: '#b5aa45' },
    { name: '西伯利亚', color: '#8f76de' },
    { name: '金字塔', color: '#03a9f4' },
  ]

  attr_accessor :cities
  attr_accessor :player_ping, :player_pong, :players,
  attr_accessor :map_source, :room
  attr_accessor :runing

  def initialize(player_ping, player_pong, cities = CITIES)
    @cities = cities
    @player_ping = player_ping
    @player_pong = player_pong
    # @room = generate_rand

    # setup
  end

  def player_can_in?(player)
    z_players = Array(@players)
    if z_players.length >= 2
      z_players.include?(player)
    else
      true
    end
  end

  def runing?
    @runing
  end

  def set_player(player)
    z_players = Array(@players)
    if !z_players.include?(player)
      @players << player
      Game.update(self.room, self)
    end
  end

  def player_ready?
    Array(@players).length == 2
  end

  def setup
    # 初始化卡牌
    cards = Card.init_cards(@cities)

    # 每人8张手牌
    player_ping_in_hands = cards.pop(8)
    player_pong_in_hands = cards.pop(8)

    # 每个城市的当前状态
    cities_status = {}
    @cities.each do |city|
      cities_status[city[:name]] = {
        "#{@player_ping}": [],  # 选手A下的牌
        "#{@player_pong}": [],  # 选手B下的牌
        "recycle_bin": []       # 回收队列的牌
      }
    end

    @map_source = {
      # "room": @room,
      "players": [@player_ping, @player_pong],
      "#{@player_ping}": {
        hand_cards: player_ping_in_hands    # 手牌
      },
      "#{@player_pong}": {
        hand_cards: player_pong_in_hands    # 手牌
      },
      leave_cards: cards, # 牌堆剩余的牌
      cities: @cities,
      cities_status: cities_status
    }
  end

  # 是否已经包含2名选手
  def ready?
    @player_ping && @player_pong
  end

  private
  def generate_rand
    SecureRandom.urlsafe_base64(6)
  end

  class << self
    # Game.start("FoTuRF6f", "xiaodong", "other")
    def start(room, player_ping, player_pong)
      raise '用户出错' if room.blank? || player_ping.blank? || player_pong.blank?

      game = self.new(player_ping, player_pong)

      room_key = "room:#{room}"
      Rails.cache.write(room_key, game.map_source)

      puts JSON.pretty_generate game.map_source.as_json
    end

    def fetch(room)
      room_key = "room:#{room}"
      Rails.cache.fetch(room_key)
    end

    def update(room, game)
      room_key = "room:#{room}"
      Rails.cache.write(room_key, game)
    end

    # 进入房间，此时先不用初始化卡牌
    def into(room)
      room_key = "room:#{room}"
      game = Rails.cache.fetch(room_key) do

      end
    end

  end
end
