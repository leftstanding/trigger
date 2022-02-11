defmodule Trigger.Controller do
 @moduledoc """
 Documentation for 'Trigger'.
 """

  def load({function, args_list}), do: load(%{}, function, args_list)

  def load(function), do: load(%{}, function, [])

  def load(function, args) when is_list(args), do: load(%{}, function, args)

  def load(function, args) when is_map(function) != true, do: load(%{}, function, [args])

  def load(%{} = functions, {function, args_list}), do: load(functions, function, args_list)

  def load(%{} = functions, function, args \\ []) do
    index = Enum.count(functions)
    args = maybe_to_list(args)

    Map.put(functions, index, {function, args})
  end

  def partial(function), do: function

  def partial({function, args_list}, args) do
    args = args_list ++ maybe_to_list(args)

    {function, args}
  end

  def partial(function, args) do
    args = maybe_to_list(args)
    {function, args}
  end

  def execute(functions, opts \\ [])
  def execute(functions, [raise: true] = opts) do
    opts = Keyword.delete(opts, :raise)
    try do
      execute(functions, opts)
    rescue
      e -> e
    end
  end

  def execute(functions, opts) do
    functions =
      case Keyword.get(opts, :ordered, false) do
        true -> Enum.sort(functions)
        false -> functions
      end

    case Keyword.get(opts, :return_results, false) do
      true ->
        functions
        |> execute_apply()
        |> report()

      false ->
        execute_apply(functions)

        {:ok, :completed}
    end
  end

  defp execute_apply(functions) do
    for {_i, tuple} <- functions do
      case tuple do
        {fun, args} when is_function(fun) -> apply(fun, args)
        {:ok, result} -> result
        {_args, [fun]} when is_function(fun) ->
          {:error, """
            wrong argument order, did you mean load(function, [arguments])?
            #{inspect tuple}
            """
          }
        error -> {:error, error}
      end
    end
  end

  defp report(results) do
    case Keyword.get(results, :error, nil) do
      nil -> {:ok, results}
      _ -> {:error, results}
    end
  end

  def maybe_to_list(args), do: is_list(args) && args || [args]

end
