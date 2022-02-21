defmodule Falco.ServerTest do
  use ExUnit.Case

  defmodule Greeter.Service do
    use GRPC.Service, name: "hello"
  end

  defmodule Greeter.Server do
    use Falco.Server, service: Greeter.Service
  end

  test "stop/2 works" do
    assert {nil, %{"hello" => Falco.ServerTest.Greeter.Server}} =
             Falco.Server.stop(Greeter.Server, adapter: Falco.Test.ServerAdapter)
  end

  test "send_reply/2 works" do
    stream = %Falco.Server.Stream{adapter: Falco.Test.ServerAdapter, codec: Falco.Codec.Erlpack}
    response = <<1, 2, 3, 4, 5, 6, 7, 8>>
    assert %Falco.Server.Stream{} = Falco.Server.send_reply(stream, response)
  end
end
