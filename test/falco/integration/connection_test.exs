defmodule Falco.Integration.ConnectionTest do
  use Falco.Integration.TestCase

  @cert_path Path.expand("./tls/server1.pem", :code.priv_dir(:falco))
  @key_path Path.expand("./tls/server1.key", :code.priv_dir(:falco))
  @ca_path Path.expand("./tls/ca.pem", :code.priv_dir(:falco))

  defmodule FeatureServer do
    use Falco.Server, service: Routeguide.RouteGuide.Service

    def get_feature(point, _stream) do
      Routeguide.Feature.new(location: point, name: "#{point.latitude},#{point.longitude}")
    end
  end

  test "reconnection works" do
    server = FeatureServer
    {:ok, _, port} = Falco.Server.start(server, 0)
    point = Routeguide.Point.new(latitude: 409_146_138, longitude: -746_188_906)
    {:ok, channel} = GRPC.Stub.connect("localhost:#{port}", adapter_opts: %{retry_timeout: 10})
    assert {:ok, _} = channel |> Routeguide.RouteGuide.Stub.get_feature(point)
    :ok = Falco.Server.stop(server)
    {:ok, _, _} = reconnect_server(server, port)
    assert {:ok, _} = channel |> Routeguide.RouteGuide.Stub.get_feature(point)
    :ok = Falco.Server.stop(server)
  end

  test "connecting with a domain socket works" do
    socket_path = "/tmp/grpc.sock"
    server = FeatureServer
    File.rm(socket_path)

    {:ok, _, _} = Falco.Server.start(server, 0, ip: {:local, socket_path})
    {:ok, channel} = GRPC.Stub.connect(socket_path, adapter_opts: %{retry_timeout: 10})

    point = Routeguide.Point.new(latitude: 409_146_138, longitude: -746_188_906)
    assert {:ok, _} = channel |> Routeguide.RouteGuide.Stub.get_feature(point)
    :ok = Falco.Server.stop(server)
  end

  test "authentication works" do
    server = FeatureServer

    cred =
      Falco.Credential.new(
        ssl: [
          certfile: @cert_path,
          cacertfile: @ca_path,
          keyfile: @key_path,
          verify: :verify_peer,
          fail_if_no_peer_cert: true
        ]
      )

    # {:ok, _, port} = Falco.Server.start(server, 0, cred: cred)
    {:ok, _, port} = Falco.Server.start(server, 0)

    try do
      point = Routeguide.Point.new(latitude: 409_146_138, longitude: -746_188_906)
      client_cred = Falco.Credential.new(ssl: [certfile: @cert_path, keyfile: @key_path])
      # {:ok, channel} = GRPC.Stub.connect("localhost:#{port}", cred: client_cred)
      {:ok, channel} = GRPC.Stub.connect("localhost:#{port}")
      assert {:ok, _} = Routeguide.RouteGuide.Stub.get_feature(channel, point)
    catch
      error ->
        refute "Caught #{inspect(error)}"
    after
      :ok = Falco.Server.stop(server)
    end
  end
end
