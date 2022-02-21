defmodule Interop.App do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      supervisor(Falco.Server.Supervisor, [{Interop.Endpoint, 10000}])
    ]

    Falco.Observability.Prometheus.ServerInterceptor.setup()
    Falco.Observability.Prometheus.ClientInterceptor.setup()
    :prometheus_httpd.start()
    Interop.ServerInterceptor.Statix.connect()

    opts = [strategy: :one_for_one, name: __MODULE__]
    Supervisor.start_link(children, opts)
  end
end
