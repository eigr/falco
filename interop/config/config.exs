import Config

config :prometheus, Falco.Observability.Prometheus.ServerInterceptor,
  latency: :histogram

config :prometheus, Falco.Observability.Prometheus.ClientInterceptor,
  latency: :histogram

# config :falco, start_server: true

# config :logger, level: :debug
config :logger, level: :warn
