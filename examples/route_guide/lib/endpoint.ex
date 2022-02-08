defmodule Routeguide.Endpoint do
  use Falco.Endpoint

  intercept Falco.Logger.Server
  run Routeguide.RouteGuide.Server
end
