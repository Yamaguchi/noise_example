# frozen_string_literal: true

module Noise::Example
  module Messages
    Algebrick.type do
      variants  Connected = type { fields! conn: Object },
                Message = type { fields! data: String, conn: Object },
                Received = type { fields! data: String, conn: Object },
                HandshakeCompleted = type { fields! conn: Object }
    end

    module Message
      def to_s
        "Message:#{[data.bth, conn]}"
      end
    end
    module Received
      def to_s
        "Received:#{[data.bth, conn]}"
      end
    end
  end
end
