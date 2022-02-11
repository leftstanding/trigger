defmodule Trigger.RemoteTest do
  use ExUnit.Case
  doctest Trigger

  alias Trigger.Remote

  describe "load_initial/2 " do
    test "can initializes an agent and loads a function" do
      twenty_five = fn -> 5 * 5 end
      assert {:ok, pid} = Remote.load_initial(twenty_five)
      assert {:ok, [25]} = Remote.execute(pid, return_results: true)
    end
  end

  describe "load/3 " do
    test "can load multiple functions" do
      identity = fn x -> x end
      stubborn = fn _x -> 3 end
      best_number = fn _x -> 9 end

      {:ok, pid} = Remote.load_initial(identity, 1)
      Remote.load(pid, stubborn, 2)
      Remote.load(pid, best_number, 3)

      assert {:ok, [1, 3, 9]} = Remote.execute(pid, return_results: true, ordered: true)
    end

    test "can load nested functions" do
      identity = fn x -> x end
      stubborn = fn _x -> 3 end
      best_number = fn _x -> 9 end

      {:ok, inner_pid} = Remote.load_initial(identity, 1)
      {:ok, outer_pid} = Remote.load_initial(&Remote.execute/1, inner_pid)
      Remote.load(outer_pid, stubborn, 2)
      Remote.load(outer_pid, best_number, 3)

      assert {:ok, [{:ok, :completed}, 3, 9]} = Remote.execute(outer_pid, return_results: true)
    end
  end
end
