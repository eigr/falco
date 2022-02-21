defmodule Interop.Endpoint do
  use Falco.Endpoint

  intercept Falco.Logger.Server
  intercept Falco.Observability.Prometheus.ServerInterceptor
  intercept Interop.ServerInterceptor

  run Interop.Server
end
