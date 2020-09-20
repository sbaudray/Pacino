defmodule PacinoTest do
  use ExUnit.Case
  doctest Pacino

  test "greets the world" do
    assert Pacino.hello() == :world
  end
end
