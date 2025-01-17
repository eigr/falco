defmodule Falco.Message.ProtobufTest do
  use ExUnit.Case, async: true

  defmodule Helloworld.HelloRequest do
    use Protobuf

    defstruct [:name]
    field(:name, 1, optional: true, type: :string)
  end

  defmodule Helloworld.HelloReply do
    use Protobuf

    defstruct [:message]
    field(:message, 1, optional: true, type: :string)
  end

  test "encode/2 works for matched arguments" do
    request = Helloworld.HelloRequest.new(name: "elixir")

    assert <<10, 6, 101, 108, 105, 120, 105, 114>> =
             Falco.Message.Protobuf.encode(Helloworld.HelloRequest, request)
  end

  test "decode/2 works" do
    msg = <<10, 6, 101, 108, 105, 120, 105, 114>>
    request = Helloworld.HelloRequest.new(name: "elixir")
    assert ^request = Falco.Message.Protobuf.decode(Helloworld.HelloRequest, msg)
  end

  test "decode/2 returns wrong result for mismatched arguments" do
    # encoded HelloRequest
    msg = <<10, 6, 101, 108, 105, 120, 105, 114>>
    request = Helloworld.HelloReply.new(message: "elixir")
    assert ^request = Falco.Message.Protobuf.decode(Helloworld.HelloReply, msg)
  end
end
