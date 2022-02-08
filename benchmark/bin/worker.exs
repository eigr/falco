require Logger

[arg] = System.argv()
[_, port] = String.split(arg, "=")
port = String.to_integer(port)

{:ok, pid, port} =
  Falco.Server.start(Grpc.Testing.WorkerService.Server, port, local: %{main_pid: self()})

defmodule Main do
  def loop do
    receive do
      {:quit, _} ->
        Logger.debug("Got msg quit")
        Process.sleep(1000)
        Falco.Server.stop(Grpc.Testing.WorkerService.Server)

      msg ->
        Logger.debug("Got not quit msg #{inspect(msg)}")
        Process.sleep(1000)
        loop()
    end
  end
end

Main.loop()
