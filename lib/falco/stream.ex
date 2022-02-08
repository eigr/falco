defmodule Falco.Stream do
  @moduledoc """
  Some useful operations for streams.
  """

  @doc """
  Get headers from server stream.

  For the client side, you should use `:return_headers` option to get headers,
  see `Falco.Stub` for details.
  """
  @spec get_headers(Falco.Server.Stream.t()) :: map
  def get_headers(%Falco.Server.Stream{adapter: adapter} = stream) do
    headers = adapter.get_headers(stream.payload)
    Falco.Transport.HTTP2.decode_headers(headers)
  end
end
