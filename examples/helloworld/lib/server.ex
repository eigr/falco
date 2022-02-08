defmodule Helloworld.Greeter.Server do
  use Falco.Server, service: Helloworld.Greeter.Service

  @spec say_hello(Helloworld.HelloRequest.t(), Falco.Server.Stream.t()) ::
          Helloworld.HelloReply.t()
  def say_hello(request, _stream) do
    Helloworld.HelloReply.new(message: "Hello #{request.name}")
  end
end
