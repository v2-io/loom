defmodule Loom.TagsTest do
  use ExUnit.Case, async: true

  alias Loom.Tags

  test "normalizes hierarchical tags" do
    tags = [" Elixir/OTP /GenServer ", :"AI/Agents", "custom tag", ""]

    assert Tags.normalize(tags) == ["ai/agents", "custom-tag", "elixir/otp/genserver"]
  end
end
