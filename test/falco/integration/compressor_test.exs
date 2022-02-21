defmodule Falco.Integration.CompressorTest do
  use Falco.Integration.TestCase

  defmodule HelloServer do
    use Falco.Server,
      service: Helloworld.Greeter.Service,
      compressors: [Falco.Compressor.Gzip]

    def say_hello(%{name: name = "only client compress"}, stream) do
      %{"grpc-encoding" => "gzip"} = Falco.Stream.get_headers(stream)
      Helloworld.HelloReply.new(message: "Hello, #{name}")
    end

    def say_hello(%{name: name = "only server compress"}, stream) do
      if Falco.Stream.get_headers(stream)["grpc-encoding"] do
        raise "grpc-encoding exists!"
      end

      Falco.Server.set_compressor(stream, Falco.Compressor.Gzip)
      Helloworld.HelloReply.new(message: "Hello, #{name}")
    end

    def say_hello(%{name: name = "both compress"}, stream) do
      %{"grpc-encoding" => "gzip"} = Falco.Stream.get_headers(stream)
      Falco.Server.set_compressor(stream, Falco.Compressor.Gzip)
      Helloworld.HelloReply.new(message: "Hello, #{name}")
    end
  end

  defmodule NoCompressServer do
    use Falco.Server,
      service: Helloworld.Greeter.Service

    def say_hello(%{name: name}, _stream) do
      Helloworld.HelloReply.new(message: "Hello, #{name}")
    end
  end

  defmodule HelloStub do
    use GRPC.Stub, service: Helloworld.Greeter.Service
  end

  test "only client compress" do
    run_server(HelloServer, fn port ->
      {:ok, channel} = GRPC.Stub.connect("localhost:#{port}")

      name = "only client compress"
      req = Helloworld.HelloRequest.new(name: name)

      {:ok, reply, headers} =
        channel
        |> HelloStub.say_hello(req, compressor: Falco.Compressor.Gzip, return_headers: true)

      assert reply.message == "Hello, #{name}"
      refute headers[:headers]["grpc-encoding"]
    end)
  end

  test "only server compress" do
    run_server(HelloServer, fn port ->
      {:ok, channel} = GRPC.Stub.connect("localhost:#{port}")

      name = "only server compress"
      req = Helloworld.HelloRequest.new(name: name)

      # no accept-encoding header
      {:ok, reply, headers} = channel |> HelloStub.say_hello(req, return_headers: true)
      assert reply.message == "Hello, #{name}"
      refute headers[:headers]["grpc-encoding"]

      {:ok, reply, headers} =
        channel
        |> HelloStub.say_hello(req,
          return_headers: true,
          accepted_compressors: [Falco.Compressor.Gzip]
        )

      assert reply.message == "Hello, #{name}"
      assert headers[:headers]["grpc-encoding"]
    end)
  end

  test "both sides compress" do
    run_server(HelloServer, fn port ->
      {:ok, channel} = GRPC.Stub.connect("localhost:#{port}")

      name = "both compress"
      req = Helloworld.HelloRequest.new(name: name)

      {:ok, reply, headers} =
        channel
        |> HelloStub.say_hello(req, compressor: Falco.Compressor.Gzip, return_headers: true)

      assert reply.message == "Hello, #{name}"
      assert headers[:headers]["grpc-encoding"]
    end)
  end

  test "error when server doesn't support" do
    run_server(NoCompressServer, fn port ->
      {:ok, channel} = GRPC.Stub.connect("localhost:#{port}")

      name = "both compress"
      req = Helloworld.HelloRequest.new(name: name)

      assert {:error, %Falco.RPCError{message: _, status: 12}} =
               channel
               |> HelloStub.say_hello(req, compressor: Falco.Compressor.Gzip, return_headers: true)
    end)
  end
end
