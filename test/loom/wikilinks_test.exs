defmodule Loom.WikilinksTest do
  use ExUnit.Case, async: true

  alias Loom.Wikilinks

  test "converts module references" do
    assert Wikilinks.convert("See `Sample.Module`.") == "See [[Sample.Module]]."
  end

  test "converts module function references" do
    assert Wikilinks.convert("Call `Sample.Module.run/2`.") ==
             "Call [[Sample.Module#run/2]]."
  end

  test "converts local function references" do
    assert Wikilinks.convert("Refer to `start_link/1`.") == "Refer to [[#start_link/1]]."
  end
end
