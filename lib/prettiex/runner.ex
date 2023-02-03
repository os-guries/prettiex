defmodule Prettiex.Runner do
  alias Prettiex.Check.All
  alias Prettiex.Check.Definition
  alias Prettiex.Check.Sequence
  alias Prettiex.Check.Meta
  alias Prettiex.Check.Pattern
  alias Prettiex.Issue

  def run(module, ast) do
    check = module.spark_dsl_config[[:check]]

    Enum.flat_map(check.entities, &interpret(check, &1, ast))
  end

  defp interpret(_check, %Meta{name: name}, _ast) do
    IO.puts(name)
    []
  end

  defp interpret(check, %Definition{all: all}, ast) do
    Enum.flat_map(all, &interpret(check, &1, ast))
  end

  defp interpret(check, %All{patterns: patterns}, ast) do
    Enum.flat_map(patterns, &interpret(check, &1, ast))
  end

  defp interpret(check, %Pattern{form: form, skip?: skip?}, ast) do
    Prettiex.collect(ast, fn node ->
      if matches?(form, node) and not skip? do
        emit_issue!(check)
      else
        :continue
      end
    end)
  end

  defp interpret(_check, _node, _ast) do
    []
  end

  defp matches?({a, _, a_children}, {b, _, b_children}) do
    cond do
      a == b and is_nil(a_children) -> true
      a == b and children_matches?(a_children, b_children) -> true
      true -> false
    end
  end

  defp matches?(_, _) do
    false
  end

  defp children_matches?(a, b) do
    Enum.zip(a, b)
    |> Enum.all?(fn {aa, bb} -> matches?(aa, bb) end)
  end

  defp emit_issue!(%{entities: [%Meta{} = meta | _]}) do
    %Issue{name: meta.name, message: meta.message}
  end
end
