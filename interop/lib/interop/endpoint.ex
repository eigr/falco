defmodule Interop.Endpoint do
  use Falco.Endpoint

  intercept Falco.Logger.Server
  intercept GRPCPrometheus.ServerInterceptor
  intercept Interop.ServerInterceptor

  run Interop.Server
end
