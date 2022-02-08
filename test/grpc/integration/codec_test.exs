defmodule Falco.Integration.CodecTest do
  use Falco.Integration.TestCase

  defmodule NotRegisteredCodec do
    @behaviour Falco.Codec

    def name() do
      "not-registered"
    end

    def pack_encoded(binary), do: binary

    def prepare_decode(binary), do: binary

    def encode(struct) do
      :erlang.term_to_binary(struct)
    end

    def decode(_binary, _module) do
      :fail
    end
  end

  defmodule HelloServer do
    use Falco.Server,
      service: Helloworld.Greeter.Service,
      codecs: [Falco.Codec.Proto, Falco.Codec.Erlpack, Falco.Codec.WebText]

    def say_hello(req, _stream) do
      Helloworld.HelloReply.new(message: "Hello, #{req.name}")
    end
  end

  defmodule HelloErlpackStub do
    use Falco.Stub, service: Helloworld.Greeter.Service
  end

  test "Says hello over erlpack, GRPC-web-text" do
    run_server(HelloServer, fn port ->
      {:ok, channel} = Falco.Stub.connect("localhost:#{port}")
      name = "Mairbek"
      req = Helloworld.HelloRequest.new(name: name)

      {:ok, reply} = channel |> HelloStub.say_hello(req, codec: Falco.Codec.Erlpack)
      assert reply.message == "Hello, #{name}"

      {:ok, reply} = channel |> HelloStub.say_hello(req, codec: Falco.Codec.WebText)
      assert reply.message == "Hello, #{name}"

      # verify that proto still works
      {:ok, reply} = channel |> HelloStub.say_hello(req, codec: Falco.Codec.Proto)

      assert reply.message == "Hello, #{name}"

      # codec not registered
      {:error, reply} = channel |> HelloStub.say_hello(req, codec: NotRegisteredCodec)

      assert %Falco.RPCError{
               status: Falco.Status.unimplemented(),
               message: "No codec registered for content-type application/grpc+not-registered"
             } == reply
    end)
  end
end
