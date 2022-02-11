defmodule Trigger do
  @moduledoc """
  Documentation for `Trigger`.
  """

  alias Trigger.Controller

  defdelegate load(function), to: Controller
  defdelegate load(function, args), to: Controller
  defdelegate load(functions, function, args), to: Controller

  defdelegate partial(function), to: Controller
  defdelegate partial(function, args), to: Controller

  defdelegate execute(functions), to: Controller
  defdelegate execute(functions, opts), to: Controller
end
