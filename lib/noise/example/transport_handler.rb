# frozen_string_literal: true

module Noise
  module Example
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
            make_writer.tap(&:start_handshake)
          else
            make_reader.tap(&:start_handshake)
          end
      end

      def on_message(message)
        log(Logger::DEBUG, message)
        case @status
        when Status::HANDSHAKE
          match message, (on Connected.(~any) do |conn|
            payload = @connection.write_message('')
            reference.parent << Act[PREFIX + payload, conn]
          end), (on Received.(~any, ~any) do |data, conn|
            @buffer += data
            if @buffer.bytesize < expected_length(@connection)
              # stay
            else
              throw "invalid transport prefix #{@buffer[0]}" unless @buffer[0] == PREFIX
              payload = @buffer[1..expected_length(@connection)]
              remainder = @buffer[expected_length(@connection)..-1]
              _ = @connection.read_message(payload)

              unless @connection.handshake_finished
                payload = @connection.write_message('')
                reference.parent << Act[PREFIX + payload, conn]
              end

              if @connection.handshake_finished
                rs = @connection.protocol.keypairs[:rs][1]
                reference.parent << HandshakeCompleted[self, conn, rs]
                @status = Status::WAITING_FOR_LISTENER
              end
              @buffer = remainder
            end
          end)
        when Status::WAITING_FOR_LISTENER
          match message, (on Received.(~any, any) do |data|
            @buffer += data
          end), (on Listener.(any) do
            _, remainder = decrypt(@buffer) unless @buffer.empty?
            # send_to(listener, plaintext)
            @buffer = remainder || +''
            @status = Status::WAITING_FOR_CYPHERTEXT
          end)
        when Status::WAITING_FOR_CYPHERTEXT
          match message, (on Received.(~any, any) do |data|
            @buffer += data
            plaintext, remainder = decrypt(@buffer)
            log(Logger::DEBUG, "message received! #{plaintext} #{plaintext.bth}")
            # send_to(listener, plaintext)
            @buffer = remainder || +''
          end), (on Message.(~any) do |data|
            ciphertext = encrypt(data)
            reference.parent << Send[ciphertext]
          end)
        end
      end

      def encrypt(data)
        @connection.encrypt(data)
      end

      def decrypt(buffer)
        @connection.decrypt(buffer)
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
end
