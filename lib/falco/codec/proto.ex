defmodule Falco.Codec.Proto do
  @behaviour Falco.Codec

  def name() do
    "proto"
  end

  def encode(struct) do
    Protobuf.Encoder.encode(struct)
  end

  def pack_encoded(binary), do: binary

  def prepare_decode(binary), do: binary

  def decode(binary, module) do
    Protobuf.Decoder.decode(binary, module)
  end
end
