defmodule Prettiex.Runner do
  alias Prettiex.Check.All
  alias Prettiex.Check.Definition
  alias Prettiex.Check.Meta
  alias Prettiex.Issue
  alias Prettiex.Check.Sequence
  alias Prettiex.AST
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
    matches? = patterns |> find_single_matches(ast) |> Enum.all?(&(&1 == :match))

    if matches? do
      [emit_issue!(check)]
    else
      []
    end
  end

  defp interpret(check, %Sequence{patterns: patterns}, ast) do
    matches? = patterns |> find_sibling_matches(ast) |> Enum.any?(&(&1 == :match))

    if matches? do
      [emit_issue!(check)]
    else
      []
    end
  end

  defp interpret(_check, _node, _ast) do
    []
  end

  defp find_single_matches(
         [pattern | patterns],
         ast,
         initial_matches \\ []
       ) do
    {_new_ast, matches} =
      Macro.prewalk(ast, initial_matches, fn node, matches ->
        if AST.matches?(pattern.form, node) do
          {node, [if(pattern.skip?, do: :skip_match, else: :match) | matches]}
        else
          {node, matches}
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
      |> Z.traverse(initial_matches, fn zipper, matches ->
        sibling = Z.right(zipper)

        if AST.matches?(p1.form, Z.node(zipper)) and not is_nil(sibling) and
             AST.matches?(p2.form, Z.node(sibling)) do
          {zipper, [:match | matches]}
        else
          {zipper, matches}
        end
      end)

    find_sibling_matches(patterns, ast, matches)
  end

  defp find_sibling_matches([_] = _patterns, _ast, initial_matches) do
    initial_matches
  end

  defp emit_issue!(%{entities: [%Meta{} = meta | _]}) do
    %Issue{name: meta.name, message: meta.message}
  end
end
