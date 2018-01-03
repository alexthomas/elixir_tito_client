defmodule TitoTest do
  use ExUnit.Case
  doctest Tito

  test "greets the world" do
    assert Tito.hello() == :world
  end
end
