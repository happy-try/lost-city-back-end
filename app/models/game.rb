class Game
  CITIES = [
    { name: '金字塔', color: 'yellow' },
    { name: '亚马逊雨林', color: 'green' },
    { name: '撒哈拉沙漠', color: 'yellow' },
    { name: '喜马拉雅山', color: 'red' },
    { name: '西伯利亚', color: 'green' }
  ]

  attr_accessor :cities, :player_ping, :player_pong, :map_source, :room

  def initialize(player_ping, player_pong, cities = CITIES)
    @cities = cities
    @player_ping = player_ping
    @player_pong = player_pong
    @room = generate_rand

    setup
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
      "room": @room,
      "players": [@player_ping, @player_pong],
      "#{@player_ping}": {
        hand_cards: []    # 手牌
      },
      "#{@player_pong}": {
        hand_cards: []    # 手牌
      },
      leave_cards: cards, # 牌堆剩余的牌
      cities: @cities
    }.merge(cities_status)
  end

  private
  def generate_rand
    SecureRandom.urlsafe_base64(6)
  end

  class << self
    # Game.start("xiaodong", "other")
    def start(player_ping, player_pong)
      raise '用户出错' if player_ping.blank? || player_pong.blank?

      game = self.new(player_ping, player_pong)

      room_key = "room:#{game.room}"
      Rails.cache.write(room_key, expires_in: 24.hours) do
        game.map_source
      end

      puts JSON.pretty_generate game.map_source.as_json
    end

    def fetch(room)
      room_key = "room:#{room}"
      Rails.cache.fetch(room_key)
    end
  end
end
