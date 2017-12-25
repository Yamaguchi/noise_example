# frozen_string_literal: true

module Noise::Example
  class Server < Concurrent::Actor::RestartingContext
    include Algebrick::Matching
    include Noise::Example::Messages

    def self.start_server(host, port, static_key, ephemeral_key)
      spawn(:server, static_key, ephemeral_key).tap do |me|
        EM.start_server(host, port, ServerConnection, me, static_key, ephemeral_key)
      end
    end

    def initialize(static_key, ephemeral_key)
      @static_key = static_key
      @ephemeral_key = ephemeral_key
    end

    def on_message(message)
      match message, (on Connected.(~any) do |conn|
        conn.transport = TransportHandler.spawn(:transport, @static_key, @ephemeral_key)
      end), (on Act.(~any, ~any) do |data, conn|
        conn&.send_data(data)
      end), (on HandshakeCompleted.(~any, ~any, ~any) do |transport, conn, remote_key|
        log(Logger::DEBUG, "Handshake Completed! #{remote_key.bth}")
        transport << Listener[nil]
      end)
    end
  end

  class ServerConnection < EM::Connection
    include Concurrent::Concern::Logging
    include Noise::Example::Messages

    attr_accessor :transport

    def initialize(server, static_key, ephemeral_key)
      @server = server
      @static_key = static_key
      @ephemeral_key = ephemeral_key
    end

    def post_init
      log(Logger::DEBUG, '/server', 'post_init')
      @server << Connected[self]
    end

    def connection_completed
      log(Logger::DEBUG, '/server', 'connection_completed')
    end

    def receive_data(data)
      log(Logger::DEBUG, '/server', "receive_data #{data.bth}")
      transport << Received[data, self]
    end

    def unbind(reason = nil)
      log(Logger::DEBUG, '/server', "unbind #{reason}")
    end

    def to_s
      'Noise::Example::ServerConnection'
    end
  end
end
