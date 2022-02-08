defmodule Falco.MessageTest do
  use ExUnit.Case, async: true

  doctest Falco.Message

  test "compressor works" do
    message = String.duplicate("foo", 100)

    # 10th byte is the operating system ID
    assert {:ok,
            data =
              <<1, 0, 0, 0, 27, 31, 139, 8, 0, 0, 0, 0, 0, 0, _, 75, 203, 207, 79, 27, 69, 196,
                33, 0, 41, 249, 122, 62, 44, 1, 0, 0>>,
            32} = Falco.Message.to_data(message, %{compressor: Falco.Compressor.Gzip})

    assert {:ok, message} == Falco.Message.from_data(%{compressor: Falco.Compressor.Gzip}, data)
  end
end
