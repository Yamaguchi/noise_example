# frozen_string_literal: true

module Noise::Example
  module Messages
    Algebrick.type do
      variants  Connected = type { fields! conn: Object },
                Act = type { fields! data: String, conn: Object },
                Received = type { fields! data: String, conn: Object },
                HandshakeCompleted = type { fields! transport: Object, conn: Object, remote_key: String },
                Listener = type { fields! listner: Object },
                Message = type { fields! data: String},
                Send = type { fields! ciphertext: String}
    end

    module Act
      def to_s
        "Act:#{[data.bth, conn]}"
      end
    end
    module Received
      def to_s
        "Received:#{[data.bth, conn]}"
      end
    end
    module Message
      def to_s
        "Message:#{[data.bth]}"
      end
    end
  end
end
