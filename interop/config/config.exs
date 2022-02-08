use Mix.Config

config :prometheus, GRPCPrometheus.ServerInterceptor,
  latency: :histogram

config :prometheus, GRPCPrometheus.ClientInterceptor,
  latency: :histogram

# config :falco, start_server: true

# config :logger, level: :debug
config :logger, level: :warn
