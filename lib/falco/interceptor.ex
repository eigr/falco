defmodule Falco.ServerInterceptor do
  @moduledoc """
  Interceptor on server side. See `Falco.Endpoint`.
  """
  alias Falco.Server.Stream

  @type options :: any
  @type rpc_return :: {:ok, Stream.t(), struct} | {:ok, Stream.t()} | {:error, Falco.RPCError.t()}
  @type next :: (Falco.Server.rpc_req(), Stream.t() -> rpc_return)

  @callback init(options) :: options
  @callback call(Falco.Server.rpc_req(), stream :: Stream.t(), next, options) :: rpc_return
end

defmodule Falco.ClientInterceptor do
  @moduledoc """
  Interceptor on client side. See `GRPC.Stub.connect/2`.
  """
  alias Falco.Client.Stream

  @type options :: any
  @type req :: struct | nil
  @type next :: (Stream.t(), req -> GRPC.Stub.rpc_return())

  @callback init(options) :: options
  @callback call(stream :: Stream.t(), req, next, options) :: GRPC.Stub.rpc_return()
end
