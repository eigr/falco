defmodule Falco.Integration.ErplackNotypesTest do
  use Falco.Integration.TestCase

  defmodule Helloworld.Notypes.Service do
    use Falco.Service, name: "helloworld.Notypes"

    rpc :ReplyHello, :ignore, :ignore
  end

  defmodule HelloServer do
    use Falco.Server, service: Helloworld.Notypes.Service, codecs: [Falco.Codec.Erlpack]

    def reply_hello(req, _stream) do
      {:ok, "Hello, #{req}"}
    end
  end

  defmodule HelloErlpackStub do
    use Falco.Stub, service: Helloworld.Notypes.Service
  end

  test "Says hello over erlpack" do
    run_server(HelloServer, fn port ->
      {:ok, channel} =
        Falco.Stub.connect(
          "localhost:#{port}",
          interceptors: [Falco.Logger.Client],
          codec: Falco.Codec.Erlpack
        )

      name = "World"
      {:ok, reply} = channel |> HelloErlpackStub.reply_hello(name)
      assert reply == {:ok, "Hello, #{name}"}
    end)
  end

  test "Says hello over erlpack call level" do
    run_server(HelloServer, fn port ->
      {:ok, channel} =
        Falco.Stub.connect("localhost:#{port}", interceptors: [Falco.Logger.Client])

      name = "World"
      {:ok, reply} = channel |> HelloErlpackStub.reply_hello(name, codec: Falco.Codec.Erlpack)
      assert reply == {:ok, "Hello, #{name}"}
    end)
  end
end
