# gRPC Elixir

[![Hex.pm](https://img.shields.io/hexpm/v/Falco.svg)](https://hex.pm/packages/grpc)
[![Travis Status](https://travis-ci.org/elixir-grpc/Falco.svg?branch=master)](https://travis-ci.org/elixir-grpc/grpc)
[![GitHub actions Status](https://github.com/eigr/falco/workflows/CI/badge.svg)](https://github.com/eigr/falco/actions)
[![Inline docs](http://inch-ci.org/github/elixir-grpc/Falco.svg?branch=master)](http://inch-ci.org/github/elixir-grpc/grpc)

An Elixir implementation of [gRPC](http://www.Falco.io/).
The name falco is a tribute to the [Peregrine Falcon](https://en.wikipedia.org/wiki/Peregrine_falcon), a super fast bird of prey. 

**This a fork of https://github.com/elixir-grpc/grpc**

**NOTICE: Erlang/OTP needs >= 20.3.2**

**NOTICE: grpc_gun**

Now `{:gun, "~> 2.0.0", hex: :grpc_gun}` is used in mix.exs because grpc depnds on Gun 2.0,
but its stable version is not released. So I published a [2.0 version on hex](https://hex.pm/packages/grpc_gun)
with a different name. So if you have other dependencies who depends on Gun, you need to use
override: `{:gun, "~> 2.0.0", hex: :grpc_gun, override: true}`. Let's wait for this issue
https://github.com/ninenines/gun/issues/229.

## Installation

The package can be installed as:

  ```elixir
  def deps do
    [
      {:falco, github: "eigr/falco"},
      # 2.9.0 fixes some important bugs, so it's better to use ~> 2.9.0
      {:cowlib, "~> 2.9.0", override: true}
    ]
  end
  ```

## Usage

1. Generate Elixir code from proto file as [protobuf-elixir](https://github.com/tony612/protobuf-elixir#usage) shows(especially the `gRPC Support` section).
2. Implement the server side code like below and remember to return the expected message types.
```elixir
defmodule Helloworld.Greeter.Server do
  use Falco.Server, service: Helloworld.Greeter.Service

  @spec say_hello(Helloworld.HelloRequest.t, Falco.Server.Stream.t) :: Helloworld.HelloReply.t
  def say_hello(request, _stream) do
    Helloworld.HelloReply.new(message: "Hello #{request.name}")
  end
end
```

3. Start the server

You can start the gRPC server as a supervised process. First, add `Falco.Server.Supervisor` to your supervision tree.

```elixir
# Define your endpoint
defmodule Helloworld.Endpoint do
  use Falco.Endpoint

  intercept Falco.Logger.Server
  run Helloworld.Greeter.Server
end

# In the start function of your Application
defmodule HelloworldApp do
  use Application
  def start(_type, _args) do
    children = [
      # ...
      supervisor(Falco.Server.Supervisor, [{Helloworld.Endpoint, 50051}])
    ]

    opts = [strategy: :one_for_one, name: HelloworldApp]
    Supervisor.start_link(children, opts)
  end
end
```

Then start it when starting your application:

```elixir
# config.exs
config :falco, start_server: true

# test.exs
config :falco, start_server: false

$ iex -S mix
```

or run falco.server using a mix task

```
$ mix falco.server
```

4. Call rpc:
```elixir
iex> {:ok, channel} = Falco.Stub.connect("localhost:50051")
iex> request = Helloworld.HelloRequest.new(name: "falco-grpc")
iex> {:ok, reply} = channel |> Helloworld.Greeter.Stub.say_hello(request)

# With interceptors
iex> {:ok, channel} = Falco.Stub.connect("localhost:50051", interceptors: [Falco.Logger.Client])
...
```

Check [examples](examples) and [interop](interop)(Interoperability Test) for some examples.

## TODO

- [x] Unary RPC
- [x] Server streaming RPC
- [x] Client streaming RPC
- [x] Bidirectional streaming RPC
- [x] Helloworld and RouteGuide examples
- [x] Doc and more tests
- [x] Authentication with TLS
- [x] Timeout for unary calls
- [x] Errors handling
- [x] Benchmarking
- [x] Logging
- [x] Interceptors(See `Falco.Endpoint`)
- [x] [Connection Backoff](https://github.com/grpc/grpc/blob/master/doc/connection-backoff.md)
- [x] Data compression
- [x] Support other encoding(other than protobuf)
- [x] gRPC Web support

## Benchmark

1. [Simple benchmark](examples/helloworld/README.md#Benchmark) by using [ghz](https://ghz.sh/)

2. [Benchmark](benchmark) followed by official spec

## Thanks

Special thanks to the [Tubi](https://tubitv.com/) team for creating the [elixir-grpc](https://github.com/elixir-grpc) library that we based on (via fork) for this project.

## Contributing

You contributions are welcome!

Please open issues if you have questions, problems and ideas. You can create pull
requests directly if you want to fix little bugs, add small features and so on.
But you'd better use issues first if you want to add a big feature or change a
lot of code.
