defmodule Falco.Codec.Proto do
  @behaviour Falco.Codec

  def name() do
    "proto"
  end

  def encode(struct) do
    Protobuf.Encoder.encode(struct)
  end

  def decode(binary, module) do
    Protobuf.Decoder.decode(binary, module)
  end
end
