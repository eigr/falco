defmodule Benchmark.ServerManager do
  def start_server(%Grpc.Testing.ServerConfig{} = config) do
    # get security
    payload_type = Benchmark.Manager.payload_type(config.payload_config)
    start_server(payload_type, config)
  end

  def start_server(:protobuf, config) do
    cores = Benchmark.Manager.set_cores(config.core_limit)
    {:ok, pid, port} = Falco.Server.start(Grpc.Testing.BenchmarkService.Server, config.port)

    %Benchmark.Server{
      cores: cores,
      port: port,
      pid: pid,
      init_time: Time.utc_now(),
      init_rusage: Benchmark.Syscall.getrusage()
    }
  end

  def start_server(_, _), do: raise(Falco.RPCError, status: :unimplemented)
end
