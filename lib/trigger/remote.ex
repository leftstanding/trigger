defmodule Trigger.Remote do
  use Agent

  alias Trigger.Controller

  @moduledoc"""
  Documentation for 'Trigger'.
  """

  def arm do
    Agent.start_link(fn -> %{} end)
  end

  def load_initial({function, args}), do: load_initial(function, args)

  def load_initial(function, args \\ []) do
    {:ok, remote} = arm()
    case Agent.update(remote, Controller, :load, [function, args]) do
      :ok -> {:ok, remote}
      _ -> :error
    end
  end

  def load(remote, {function, args}) when is_pid(remote), do: load(remote, function, args)
  def load({function, args}, remote), do: load(remote, function, args)

  def load(remote, function, args \\ []) when is_pid(remote) do
    Agent.update(remote, Controller, :load, [function, args])
  end

  def load_covert(pass_through, remote, function, args \\ []) do
    case Keyword.get(args, :send, false) do
      false -> load(remote, function, args)
      true -> load(remote, function, [pass_through])
    end

    pass_through
  end

  def execute_covert(pass_through, remote, opts \\ []) do
    case Keyword.get(opts, :return_results, false) do
      false -> execute(remote, opts)
      true ->
        return =
          execute(remote, opts ++ [persist: true])

        Agent.cast(remote, fn _ -> return end)
    end

    pass_through
  end

  def execute(remote, opts \\ []) do
    return =
      Agent.get(remote, Controller, :execute, [opts])

    case Keyword.get(opts, :persist, false) do
      false -> Agent.stop(remote)
      true -> :ok
    end

    return
  end

  def recover(remote) do
    return = Agent.get(remote, fn state -> state end)
    Agent.stop(remote)

    return
  end

  def abort(remote), do: Agent.stop(remote)
end
