defmodule Interop.ServerInterceptor.Statix do
  use Statix
end

defmodule Interop.ServerInterceptor do
  use Falco.Observability.Statsd.ServerInterceptor, statsd_module: Interop.ServerInterceptor.Statix
end
