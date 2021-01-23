# frozen_string_literal: true

class Card
  # 类型
  # - investment: 投资卡（value -> 0）
  # - normal: 普通牌（value -> 1-10）
  TYPIES = %i[investment normal].freeze

  attr_accessor :id, :type, :color, :city, :value

  def initialize(type, color, city, value)
    @id = generate_rand
    @type = type
    @color = color
    @city = city
    @value = value
  end

  def investment?
    @type == 'investment'
  end

  private

  def generate_rand
    SecureRandom.urlsafe_base64(6)
  end

  class << self
    def init_cards(cities)
      cards = []

      cities.each do |city|
        # 三张投资卡
        3.times.each do |_value|
          cards << new('investment', city[:color], city[:name], 0)
        end

        # 9张基本卡
        (2..10).each do |value|
          cards << new('normal', city[:color], city[:name], value)
        end
      end

      cards.shuffle
    end
  end
end
