defmodule LoomTest do
  use ExUnit.Case
  doctest Loom

  test "returns the current version" do
    assert Loom.version() == "0.1.0"
  end
end
