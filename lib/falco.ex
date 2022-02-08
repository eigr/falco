defmodule Falco do
  @version Falco.Mixfile.project()[:version]

  @doc """
  Returns version of this project.
  """
  def version, do: @version

  @doc false
  def user_agent, do: "Falco/#{version()}"
end
