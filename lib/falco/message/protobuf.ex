defmodule Falco.Message.Protobuf do
  @moduledoc false

  # Module for encoding or decoding message using Protobuf.

  @spec encode(atom, struct) :: binary
  def encode(mod, struct) do
    apply(mod, :encode, [struct])
  end

  @spec decode(atom, binary) :: struct
  def decode(mod, message) do
    apply(mod, :decode, [message])
  end
end
