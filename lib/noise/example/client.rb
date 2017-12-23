# frozen_string_literal: true

module Noise::Example
  class Client < Concurrent::Actor::RestartingContext
    include Algebrick::Matching
    include Noise::Example::Messages

    module Status
      DISCONNECT = 0
      AUTHENTICATING = 1
      CONNECT = 2
    end

    def self.connect(host, port, static_key, ephemeral_key, remote_key)
      spawn(:client, static_key, ephemeral_key, remote_key).tap do |me|
        EM.connect(host, port, ClientConnection, me)
      end
    end

    def initialize(static_key, ephemeral_key, remote_key)
      @static_key = static_key
      @ephemeral_key = ephemeral_key
      @remote_key = remote_key
      @status = Status::DISCONNECT
    end

    def on_message(message)
      log(Logger::DEBUG, "#on_message #{@status} #{message}")
      case @status
      when Status::DISCONNECT
        match message, (on ~Connected do |msg|
          @transport = TransportHandler.spawn(:transport, @static_key, @ephemeral_key, remote_key: @remote_key)
          @transport << msg
          @status = Status::AUTHENTICATING
        end)
      when Status::AUTHENTICATING
        match message, (on Message.(~any, ~any) do |data, conn|
          conn&.send_data(data)
        end), (on ~Received do |msg|
          @transport << msg
        end), (on HandshakeCompleted do
          log(Logger::DEBUG, 'Handshake Completed!')
          @status = Status::CONNECT
        end)
      when Status::CONNECT
        log(Logger::DEBUG, 'Status::CONNECT')
      end
    end
  end
  class ClientConnection < EM::Connection
    include Concurrent::Concern::Logging
    include Noise::Example::Messages

    def initialize(client)
      @client = client
    end

    def post_init
      log(Logger::DEBUG, '/client', 'post_init')
    end

    def connection_completed
      log(Logger::DEBUG, '/client', 'connection_completed')
      @client << Connected[self]
    end

    def receive_data(data)
      log(Logger::DEBUG, '/client', "receive_data #{data.bth}")
      @client << Received[data, self]
    end

    def unbind(reason = nil)
      log(Logger::DEBUG, '/client', "unbind #{reason}")
    end
  end
end
