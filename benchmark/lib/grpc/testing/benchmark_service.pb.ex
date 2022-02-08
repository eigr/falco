defmodule Grpc.Testing.BenchmarkService.Service do
  @moduledoc false
  use Falco.Service, name: "grpc.testing.BenchmarkService"

  rpc :UnaryCall, Grpc.Testing.SimpleRequest, Grpc.Testing.SimpleResponse
  rpc :StreamingCall, stream(Grpc.Testing.SimpleRequest), stream(Grpc.Testing.SimpleResponse)
  rpc :StreamingFromClient, stream(Grpc.Testing.SimpleRequest), Grpc.Testing.SimpleResponse
  rpc :StreamingFromServer, Grpc.Testing.SimpleRequest, stream(Grpc.Testing.SimpleResponse)
  rpc :StreamingBothWays, stream(Grpc.Testing.SimpleRequest), stream(Grpc.Testing.SimpleResponse)
end

defmodule Grpc.Testing.BenchmarkService.Stub do
  @moduledoc false
  use Falco.Stub, service: Grpc.Testing.BenchmarkService.Service
end
