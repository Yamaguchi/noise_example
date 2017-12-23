# frozen_string_literal: true

module Noise::Example
  class TransportHandler < Concurrent::Actor::RestartingContext
    include Algebrick::Matching
    include Noise::Example::Messages

    PREFIX = '00'.htb
    PROLOGUE = '6c696768746e696e67'.htb

    module Status
      HANDSHAKE = 0
      WAITING_FOR_LISTENER = 1
      WAITING_FOR_CYPHERTEXT = 2
    end

    def initialize(static_key, ephemeral_key, remote_key: nil)
      @static_key = static_key
      @ephemeral_key = ephemeral_key
      @remote_key = remote_key
      @status = Status::HANDSHAKE
      @buffer = +''
      @connection =
        if initiator?
          connection = make_writer
          connection.start_handshake
          connection
        else
          connection = make_reader
          connection.start_handshake
          connection
        end
    end

    def on_message(message)
      log(Logger::DEBUG, message)
      case @status
      when Status::HANDSHAKE
        match message, (on Connected.(~any) do |conn|
          payload = @connection.write_message('')
          reference.parent << Message[PREFIX + payload, conn]
        end), (on Received.(~any, ~any) do |data, conn|
          @buffer += data
          if @buffer.bytesize < expected_length(@connection)
            # stay
          else
            throw "invalid transport prefix #{@buffer[0]}" unless @buffer[0] == PREFIX
            payload = @buffer[1..expected_length(@connection)]
            remainder = @buffer[expected_length(@connection)..-1]
            _ = @connection.read_message(payload)

            if @connection.handshake_finished
              rs = @connection.protocol.keypairs[:rs][1]
              reference.parent << HandshakeCompleted[conn, rs]
              @status = Status::WAITING_FOR_LISTENER
            else
              payload = @connection.write_message('')
              reference.parent << Message[PREFIX + payload, conn]
              if @connection.handshake_finished
                rs = @connection.protocol.keypairs[:rs][1]
                reference.parent << HandshakeCompleted[conn, rs]
                @status = Status::WAITING_FOR_LISTENER
              end
            end
            @buffer = remainder
          end
        end)
      when Status::WAITING_FOR_LISTENER
      when Status::WAITING_FOR_CYPHERTEXT
      end
    end

    def expected_length(connection)
      case connection.protocol.handshake_state.message_patterns.length
      when 1 then 66
      when 2, 3 then 50
      end
    end

    def initiator?
      !@remote_key.nil?
    end

    def make_writer
      initiator = Noise::Connection.new('Noise_XK_secp256k1_ChaChaPoly_SHA256')
      initiator.prologue = PROLOGUE
      initiator.set_as_initiator!
      initiator.set_keypair_from_private(Noise::KeyPair::STATIC, @static_key[0])
      initiator.set_keypair_from_private(Noise::KeyPair::EPHEMERAL, @ephemeral_key[0])
      initiator.set_keypair_from_public(Noise::KeyPair::REMOTE_STATIC, @remote_key)
      initiator
    end

    def make_reader
      responder = Noise::Connection.new('Noise_XK_secp256k1_ChaChaPoly_SHA256')
      responder.prologue = PROLOGUE
      responder.set_as_responder!
      responder.set_keypair_from_private(Noise::KeyPair::STATIC, @static_key[0])
      responder.set_keypair_from_private(Noise::KeyPair::EPHEMERAL, @ephemeral_key[0])
      responder
    end
  end
end
