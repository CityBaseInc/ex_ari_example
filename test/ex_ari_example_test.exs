defmodule ExAriExampleTest do
  use ExUnit.Case
  doctest ExAriExample

  test "greets the world" do
    assert ExAriExample.hello() == :world
  end
end
