defmodule Prettiex.Runner do
  alias Prettiex.Check.All
  alias Prettiex.Check.Definition
  alias Prettiex.Check.Meta
  alias Prettiex.Issue
  alias Prettiex.Check.Sequence
  alias Sourceror.Zipper, as: Z

  def run(module, ast) do
    check = module.spark_dsl_config[[:check]]

    Enum.flat_map(check.entities, &interpret(check, &1, ast))
  end

  defp interpret(_check, %Meta{}, _ast) do
    []
  end

  defp interpret(check, %Definition{all: all, sequence: sequence}, ast) do
    Enum.flat_map(sequence ++ all, &interpret(check, &1, ast))
  end

  defp interpret(check, %All{patterns: patterns}, ast) do
    match? = patterns |> find_single_matches(ast) |> Enum.all?(&(&1 == :match))

    if match? do
      [emit_issue!(check)]
    else
      []
    end
  end

  defp interpret(check, %Sequence{patterns: patterns}, ast) do
    match? = patterns |> find_sibling_matches(ast) |> Enum.any?(&(&1 == :match))

    if match? do
      [emit_issue!(check)]
    else
      []
    end
  end

  defp interpret(_check, _node, _ast) do
    []
  end

  defp check_matches_with(matches, checker) do
  end

  defp find_single_matches(
         [pattern | patterns],
         ast,
         initial_matches \\ []
       ) do
    {_new_ast, matches} =
      Macro.prewalk(ast, initial_matches, fn node, matches ->
        if ast_match?(pattern.form, node) do
          {node, [if(pattern.skip?, do: :skip_match, else: :match) | matches]}
        else
          {node, [:skip | matches]}
        end
      end)

    case patterns do
      [] -> matches
      remaining -> find_single_matches(remaining, ast, matches)
    end
  end

  defp find_sibling_matches(patterns, ast, initial_matches \\ [])

  defp find_sibling_matches(
         [p1, p2 | patterns],
         ast,
         initial_matches
       ) do
    {_new_ast, matches} =
      ast
      |> Z.zip()
      |> Z.traverse([], fn zipper, matches ->
        sibling = Z.right(zipper)

        if ast_match?(p1.form, Z.node(zipper)) and not is_nil(sibling) and
             ast_match?(p2.form, Z.node(sibling)) do
          {zipper, [:match | matches]}
        else
          {zipper, matches}
        end
      end)

    matches
  end

  defp find_sibling_matches([_] = patterns, ast, initial_matches) do
    initial_matches
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
