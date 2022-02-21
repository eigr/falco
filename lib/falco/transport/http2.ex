defmodule Falco.Transport.HTTP2 do
  @moduledoc false

  # A module providing functions for sending HTTP/2 requests.

  alias Falco.Transport.Utils
  alias Falco.Status

  require Logger

  def server_headers(%{codec: Falco.Codec.WebText = codec}) do
    %{"content-type" => "application/Falco-web-#{codec.name}"}
  end

  def server_headers(%{codec: codec}) do
    %{"content-type" => "application/Falco+#{codec.name}"}
  end

  @spec server_trailers(integer, String.t()) :: map
  def server_trailers(status \\ Status.ok(), message \\ "") do
    %{
      "Falco-status" => Integer.to_string(status),
      "Falco-message" => message
    }
  end

  @doc """
  Now we may not need this because gun already handles the pseudo headers.
  """
  @spec client_headers(Falco.Client.Stream.t(), map) :: [{String.t(), String.t()}]
  def client_headers(%{channel: channel, path: path} = s, opts \\ %{}) do
    [
      {":method", "POST"},
      {":scheme", channel.scheme},
      {":path", path},
      {":authority", channel.host}
    ] ++ client_headers_without_reserved(s, opts)
  end

  @spec client_headers_without_reserved(Falco.Client.Stream.t(), map) :: [
          {String.t(), String.t()}
        ]
  def client_headers_without_reserved(%{codec: codec} = stream, opts \\ %{}) do
    [
      # It seems only Falco implemenations only support "application/Falco", so we support :content_type now.
      {"content-type", content_type(opts[:content_type], codec)},
      {"user-agent", "Falco-elixir/#{opts[:Falco_version] || Falco.version()}"},
      {"te", "trailers"}
    ]
    |> append_compressor(stream.compressor)
    |> append_accepted_compressors(stream.accepted_compressors)
    |> append_custom_metadata(stream.channel.headers)
    |> append_encoding(opts[:Falco_encoding])
    |> append_timeout(opts[:timeout])
    |> append_custom_metadata(stream.headers)
    |> append_custom_metadata(opts[:metadata])

    # TODO: Falco-accept-encoding, Falco-message-type
    # TODO: Authorization
  end

  defp content_type(custom, _codec) when is_binary(custom), do: custom

  defp content_type(_, codec) do
    # Some Falco implementations don't support application/Falco+xyz,
    # to avoid this kind of trouble, use application/Falco by default
    if codec == Falco.Codec.Proto do
      "application/Falco"
    else
      "application/Falco+#{codec.name}"
    end
  end

  def extract_metadata(headers) do
    headers
    |> Enum.filter(fn {k, _} -> is_metadata(k) end)
    |> Enum.into(%{}, &decode_metadata/1)
  end

  def decode_headers(headers) do
    Enum.into(headers, %{}, fn {k, v} ->
      if is_metadata(k) do
        decode_metadata({k, v})
      else
        {k, v}
      end
    end)
  end

  def encode_metadata(metadata) do
    metadata
    |> Enum.filter(fn {k, _v} -> !is_reserved_header(to_string(k)) end)
    |> Enum.reduce(%{}, fn {k, v}, acc ->
      {new_k, new_v} = encode_metadata_pair({k, v})
      Map.update(acc, new_k, new_v, fn old_v -> Enum.join([old_v, new_v], ",") end)
    end)
  end

  defp append_encoding(headers, Falco_encoding) when is_binary(Falco_encoding) do
    Logger.warn("Falco_encoding option is deprecated, please use compressor.")
    [{"Falco-encoding", Falco_encoding} | headers]
  end

  defp append_encoding(headers, _), do: headers

  defp append_compressor(headers, compressor) when not is_nil(compressor) do
    [{"Falco-encoding", compressor.name()} | headers]
  end

  defp append_compressor(headers, _), do: headers

  defp append_accepted_compressors(headers, [_] = compressors) do
    encoding = Enum.map_join(compressors, ",", & &1.name())
    [{"Falco-accept-encoding", encoding} | headers]
  end

  defp append_accepted_compressors(headers, _), do: headers

  defp append_timeout(headers, timeout) when is_integer(timeout) do
    [{"Falco-timeout", Utils.encode_timeout(timeout)} | headers]
  end

  defp append_timeout(headers, _), do: headers

  defp append_custom_metadata(headers, metadata) when is_map(metadata) or is_list(metadata) do
    Enum.to_list(encode_metadata(metadata)) ++ headers
  end

  defp append_custom_metadata(headers, _), do: headers

  defp encode_metadata_pair({key, val}) when not is_binary(key) do
    encode_metadata_pair({to_string(key), val})
  end

  defp encode_metadata_pair({key, val}) when not is_binary(val) do
    encode_metadata_pair({key, to_string(val)})
  end

  defp encode_metadata_pair({key, val}) do
    val = if String.ends_with?(key, "-bin"), do: Base.encode64(val), else: val
    {String.downcase(to_string(key)), val}
  end

  defp decode_metadata({key, val}) do
    val = if String.ends_with?(key, "-bin"), do: Base.decode64!(val, padding: false), else: val
    {key, val}
  end

  defp is_reserved_header(":" <> _), do: true
  defp is_reserved_header("Falco-" <> _), do: true
  defp is_reserved_header("content-type"), do: true
  defp is_reserved_header("te"), do: true
  defp is_reserved_header(_), do: false

  defp is_metadata("content-length"), do: false
  defp is_metadata("user-agent"), do: false

  defp is_metadata(key) do
    !is_reserved_header(key)
  end
end