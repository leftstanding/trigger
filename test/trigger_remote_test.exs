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

    test "can load partial functions" do
      multiple = fn a, b, c -> "#{a} #{b} #{c}" end

      {:ok, pid} =
        multiple
          |> Trigger.partial()
          |> Trigger.partial("Applying")
          |> Trigger.partial([:partial, "arguments"])
          |> Remote.load_initial()

      assert {:ok, ["Applying partial arguments"]} = Remote.execute(pid, return_results: true, ordered: true)
    end

    test "can load multiple functions and partial functions" do
      identity = fn x -> x end
      stubborn = fn _x -> 3 end
      best_number = fn _x -> 9 end
      multiple = fn a, b, c -> "#{a} #{b} #{c}" end

      {:ok, pid} = Remote.load_initial(identity, 1)
      Remote.load(pid, stubborn, 2)
      multiple
        |> Trigger.partial()
        |> Trigger.partial("Applying")
        |> Trigger.partial(:partial)
        |> Trigger.partial("arguments")
        |> Remote.load(pid)
      Remote.load(pid, best_number, 3)

      assert {:ok, [1, 3, "Applying partial arguments", 9]} = Remote.execute(pid, return_results: true, ordered: true)
    end
  end

  describe "load_covert/2 " do
    test "allows calls in a pipe without interrupting control flow" do
      state = 1..9
      {:ok, remote} = Remote.arm()

      state =
        state
        |> Enum.map(fn x -> rem(x, 2) end)
        |> Enum.map(fn x -> {x, x * 3} end)
        |> Remote.load_covert(remote, &Enum.max/1, [send: true])
        |> Enum.filter(fn {y, _z} -> rem(y, 2) == 0 end)
        |> Enum.dedup()

      assert [{0, 0}] == state
      assert {:ok, [{1, 3}]} = Remote.execute(remote, return_results: true)
    end
  end

  describe "execute_covert/2 " do
    test "allows results to be retreived later" do
      identity = fn x -> x end
      add = fn x, y -> x + y end

      {:ok, remote} = Remote.load_initial(identity, 3)

      state =
        1
        |> add.(1)
        |> add.(2)
        |> add.(3)
        |> Remote.execute_covert(remote, [return_results: true])
        |> add.(4)
        |> add.(5)

      assert 16 == state
      assert {:ok, [3]} = Remote.recover(remote)
    end
  end
end
