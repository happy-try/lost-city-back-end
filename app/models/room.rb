class Room
  def initialize

  end

  class << self
    def fetch_room(room)
      Rails.cache.fetch(room) do

      end
    end
  end
end
