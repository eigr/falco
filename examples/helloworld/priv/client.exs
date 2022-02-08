{:ok, channel} = Falco.Stub.connect("localhost:50051", interceptors: [Falco.Logger.Client])

{:ok, reply} =
  channel |> Helloworld.Greeter.Stub.say_hello(Helloworld.HelloRequest.new(name: "grpc-elixir"))

IO.inspect(reply)
