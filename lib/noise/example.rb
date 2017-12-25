# frozen_string_literal: true

require 'noise/example/version'

require 'algebrick'
require 'concurrent'
require 'concurrent-edge'
require 'eventmachine'
require 'noise'

require 'pry'

module Noise
  module Example
    autoload :Client, 'noise/example/client'
    autoload :Messages, 'noise/example/messages'
    autoload :Server, 'noise/example/server'
    autoload :TransportHandler, 'noise/example/transport_handler'
  end
end

Concurrent.use_simple_logger Logger::DEBUG
# initiator Keys
# rs.pub: 0x028d7500dd4c12685d1f568b4c2b5048e8534b873319f3a8daa612b469132ec7f7
# ls.priv: 0x1111111111111111111111111111111111111111111111111111111111111111
# ls.pub: 0x034f355bdcb7cc0af728ef3cceb9615d90684bb5b2ca5f859ab0f0b704075871aa
# e.priv: 0x1212121212121212121212121212121212121212121212121212121212121212
# e.pub: 0x036360e856310ce5d294e8be33fc807077dc56ac80d95d9cd4ddbd21325eff73f7
initiator_static_key = [
  '1111111111111111111111111111111111111111111111111111111111111111'.htb,
  '034f355bdcb7cc0af728ef3cceb9615d90684bb5b2ca5f859ab0f0b704075871aa'.htb
]
initiator_ephemeral_key = [
  '1212121212121212121212121212121212121212121212121212121212121212'.htb,
  '036360e856310ce5d294e8be33fc807077dc56ac80d95d9cd4ddbd21325eff73f7'.htb
]
remote_static_key = '028d7500dd4c12685d1f568b4c2b5048e8534b873319f3a8daa612b469132ec7f7'.htb

# Responder Keys
# ls.priv=2121212121212121212121212121212121212121212121212121212121212121
# ls.pub=028d7500dd4c12685d1f568b4c2b5048e8534b873319f3a8daa612b469132ec7f7
# e.priv=0x2222222222222222222222222222222222222222222222222222222222222222
# e.pub=0x02466d7fcae563e5cb09a0d1870bb580344804617879a14949cf22285f1bae3f27
responder_static_key = [
  '2121212121212121212121212121212121212121212121212121212121212121'.htb,
  '028d7500dd4c12685d1f568b4c2b5048e8534b873319f3a8daa612b469132ec7f7.htb'
]
responder_ephemeral_key = [
  '2222222222222222222222222222222222222222222222222222222222222222'.htb,
  '02466d7fcae563e5cb09a0d1870bb580344804617879a14949cf22285f1bae3f27'.htb
]
Thread.start do
  EM.run do
    Noise::Example::Server.start_server(
      '0.0.0.0',
      9735,
      responder_static_key,
      responder_ephemeral_key
    )
  end
end
sleep(1)

EM.run do
  client = Noise::Example::Client.connect(
    '127.0.0.1',
    9735,
    initiator_static_key,
    initiator_ephemeral_key,
    remote_static_key
  )
  sleep(1)
  client << Noise::Example::Messages::Message['hello']
end
