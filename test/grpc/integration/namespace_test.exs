defmodule Falco.Integration.NamespaceTest do
  use Falco.Integration.TestCase

  defmodule FeatureServer do
    use Falco.Server, service: Routeguide.RouteGuide.Service

    def get_feature(point, _stream) do
      Routeguide.Feature.new(location: point, name: "#{point.latitude},#{point.longitude}")
    end
  end

  test "it works when outer namespace is same with inner's" do
    run_server(FeatureServer, fn port ->
      {:ok, channel} = Falco.Stub.connect("localhost:#{port}")
      point = Routeguide.Point.new(latitude: 409_146_138, longitude: -746_188_906)
      {:ok, feature} = channel |> Routeguide.RouteGuide.Stub.get_feature(point)
      assert feature == Routeguide.Feature.new(location: point, name: "409146138,-746188906")
    end)
  end
end
