defmodule Falco.Compressor.Gzip do
  @behaviour Falco.Compressor

  def name do
    "gzip"
  end

  def compress(data) do
    :zlib.gzip(data)
  end

  def decompress(data) do
    :zlib.gunzip(data)
  end
end
