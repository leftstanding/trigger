defmodule TriggerTest do
  use ExUnit.Case
  doctest Trigger

  describe "load/1 " do
    test "loads a function" do
      twenty_five = fn -> 5 * 5 end
      assert {:ok, :completed} == Trigger.load(twenty_five) |> Trigger.execute()
    end

    test "loads a function with arguments" do
      cube = fn x -> x * x end
      assert {:ok, [25]} == Trigger.load(cube, 5) |> Trigger.execute(return_results: true)
    end
  end

  describe "partial/1 " do
    test "composes simple partial functions" do
      add = fn a, b -> a + b end

      assert {:ok, [9]} == Trigger.partial(add) |> Trigger.load([4, 5]) |> Trigger.execute(return_results: true)
    end

    test "composes partial function" do
      multiple = fn a, b, c -> "#{a} #{b} #{c}" end

      partial =
        multiple
          |> Trigger.partial()
          |> Trigger.partial("Applying")
          |> Trigger.partial([:partial, "arguments"])
          |> Trigger.load()

      assert {:ok, ["Applying partial arguments"]} = Trigger.execute(partial, return_results: true, ordered: true)
    end
  end

  describe "execute/2 " do
    test "executes multiple functions" do
    twenty_five = fn -> 5 * 5 end
    ten = fn -> 5 * 2 end

    assert {:ok, :completed} ==
      Trigger.load(twenty_five)
        |> Trigger.load(ten)
        |> Trigger.execute()
    end

    test "can return results" do
    twenty_five = fn -> 5 * 5 end
    ten = fn -> 5 * 2 end

    results =
      Trigger.load(twenty_five)
        |> Trigger.load(ten)
        |> Trigger.execute(return_results: true)

    assert {:ok, results} == [10, 25] or [25, 10]
    end

    test "will validate failed results" do
      three = fn -> 3 end

      assert {:error, _error} = Trigger.load(3, three) |> Trigger.execute(return_results: true)
    end

    test "can return ordered results" do
    twenty_five = fn -> 5 * 5 end
    ten = fn -> 5 * 2 end

    assert {:ok, [25, 10]} ==
      Trigger.load(twenty_five)
        |> Trigger.load(ten)
        |> Trigger.execute(ordered: true, return_results: true)
    end

    test "can handle nested triggers" do
      three = fn -> 3 end
      five = fn -> 5 end
      identity = fn x -> x end

      inner = Trigger.load(three)
      outer = Trigger.load(Trigger.execute(inner))
        |> Trigger.load(five)
        |> Trigger.load(identity, self())

      assert {:ok, :completed} = Trigger.execute(outer)
    end

    test "can return results from nested triggers" do
      three = fn -> 3 end
      five = fn -> 5 end
      identity = fn x -> x end

      inner = Trigger.load(three)
      outer = Trigger.load(Trigger.execute(inner, return_results: true))
        |> Trigger.load(five)
        |> Trigger.load(identity, self())

      assert {:ok, [[3], 5, _pid]} = Trigger.execute(outer, return_results: true, ordered: true)
    end

   test "will validate nested failed results" do
      three = fn -> 3 end
      five = fn -> 5 end
      identity = fn x -> x end

      inner = Trigger.load(3, three)
      outer = Trigger.load(Trigger.execute(inner, return_results: true))
        |> Trigger.load(five)
        |> Trigger.load(identity, self())

      assert {:error, _error} = Trigger.execute(outer, return_results: true)
    end

   test "will fail silently with default options" do
      three = fn -> 3 end
      five = fn -> 5 end
      identity = fn x -> x end

      inner = Trigger.load(3, three)
      outer = Trigger.load(Trigger.execute(inner, return_results: true))
        |> Trigger.load(five)
        |> Trigger.load(identity, self())

      assert {:ok, :completed} = Trigger.execute(outer)
   end

   test "will raise" do
     fail_fun = fn -> "I'll die" end

     assert %BadArityError{} = Trigger.load(fail_fun, 3) |> Trigger.execute(raise: true)
   end
  end
end
