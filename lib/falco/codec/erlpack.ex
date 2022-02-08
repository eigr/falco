defmodule Falco.Codec.Erlpack do
  @behaviour Falco.Codec

  def name() do
    "erlpack"
  end

  def encode(struct) do
    :erlang.term_to_binary(struct)
  end

  def decode(binary, _module) do
    :erlang.binary_to_term(binary)
  end
end
