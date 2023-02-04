defmodule Prettiex.Runner do
  alias Prettiex.Check.All
  alias Prettiex.Check.Definition
  alias Prettiex.Check.Meta
  alias Prettiex.Issue

  def run(module, ast) do
    check = module.spark_dsl_config[[:check]]

    Enum.flat_map(check.entities, &interpret(check, &1, ast))
  end

  defp interpret(_check, %Meta{}, _ast) do
    []
  end

  defp interpret(check, %Definition{all: all}, ast) do
    Enum.flat_map(all, &interpret(check, &1, ast))
  end

  defp interpret(check, %All{patterns: patterns}, ast) do
    match? = patterns |> patterns_match?(ast) |> Enum.all?(&(&1 == :match))

    if match? do
      [emit_issue!(check)]
    else
      []
    end
  end

  defp interpret(_check, _node, _ast) do
    []
  end

  defp patterns_match?(
         [pattern | patterns],
         ast,
         initial_matches \\ []
       ) do
    {_new_ast, matches} =
      Macro.prewalk(ast, initial_matches, fn node, matches ->
        if ast_match?(pattern.form, node) do
          {node, [if(pattern.skip?, do: :skip_match, else: :match) | matches]}
        else
          {node, matches}
        end
      end)

    case patterns do
      [] -> matches
      remaining -> patterns_match?(remaining, ast, matches)
    end
  end

  defp ast_match?({a, _, a_children}, {b, _, b_children}) do
    cond do
      a == b and is_nil(a_children) -> true
      a == b and children_matches?(a_children, b_children) -> true
      true -> false
    end
  end

  defp ast_match?(_, _) do
    false
  end

  defp children_matches?(a, b) do
    Enum.zip(a, b)
    |> Enum.all?(fn {aa, bb} -> ast_match?(aa, bb) end)
  end

  defp emit_issue!(%{entities: [%Meta{} = meta | _]}) do
    %Issue{name: meta.name, message: meta.message}
  end
end
