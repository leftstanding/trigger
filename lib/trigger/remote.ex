defmodule Trigger.Remote do
  use Agent

  alias Trigger.Controller

  @moduledoc"""
  Documentation for 'Trigger'.
  """
  # TODO implement covert functions

  def start_link do
    Agent.start_link(fn -> %{} end)
  end

  def load_initial({function, args}), do: load_initial(function, args)

  def load_initial(function, args \\ []) do
    {:ok, remote} = start_link()
    case Agent.update(remote, Controller, :load, [function, args]) do
      :ok -> {:ok, remote}
      _ -> :error
    end
  end

  def load(remote, {function, args}), do: load(remote, function, args)

  def load(remote, function, args \\ []) when is_pid(remote) do
    Agent.update(remote, Controller, :load, [function, args])
  end

  def execute(remote, opts \\ []) do
    Agent.get(remote, Controller, :execute, [opts])
  end

  def abort(remote), do: Agent.stop(remote)
end
