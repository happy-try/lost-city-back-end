class GameChannel < ApplicationCable::Channel
  def subscribed
    stream_from "room_#{params[:room]}"
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
  def into_room(data)
  end

  # 下牌
  def push_card(data)
    p params
    p data

    # 检查手牌是否有该 card_id, 如果有，下到对应的城市

    # 并广播回去，进行界面变更。
    status = Game.fetch(params[:room])
    game = Game.start("xiaodong", "other")

    ActionCable.server.broadcast("room_#{params[:room]}", status)
  end

  # 取牌
  def receive_card(data)
    p params
  end
end
