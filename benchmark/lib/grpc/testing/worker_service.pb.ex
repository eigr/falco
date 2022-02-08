defmodule Grpc.Testing.WorkerService.Service do
  @moduledoc false
  use Falco.Service, name: "grpc.testing.WorkerService"

  rpc :RunServer, stream(Grpc.Testing.ServerArgs), stream(Grpc.Testing.ServerStatus)
  rpc :RunClient, stream(Grpc.Testing.ClientArgs), stream(Grpc.Testing.ClientStatus)
  rpc :CoreCount, Grpc.Testing.CoreRequest, Grpc.Testing.CoreResponse
  rpc :QuitWorker, Grpc.Testing.Void, Grpc.Testing.Void
end

defmodule Grpc.Testing.WorkerService.Stub do
  @moduledoc false
  use Falco.Stub, service: Grpc.Testing.WorkerService.Service
end
