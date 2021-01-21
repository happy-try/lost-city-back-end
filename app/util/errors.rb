module Errors
  # 自定义异常的基类
  class CustomError < StandardError
    attr_reader :code, :sub_code, :message

    # code: 大类异常（系统出错/网络问题/业务问题等等）
    # sub_code: 具体子异常
    # message: 异常。
    def initialize(code, sub_code, message)
      @code = code
      @sub_code = sub_code
      @message = message
    end

    def fetch_json
      {
        code: @code,
        sub_code: @sub_code,
        message: @message
      }
    end
  end

  class Base < CustomError
    def initialize(message)
      super(10001, :base_error, message)
    end
  end

  class GameOver < CustomError
    def initialize
      super(10002, :game_over, '游戏结束')
    end
  end
end