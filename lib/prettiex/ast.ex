defmodule Prettiex.AST do
  alias Sourceror.Zipper, as: Z

  @typep expr :: {atom, any(), atom | [expr()]}

  @spec get(expr(), atom()) :: expr() | nil
  def get(expr, target) do
    expr
    |> Z.zip()
    |> Z.find(fn
      {term, _, _} -> term == target
      term -> term == target
    end)
    |> maybe_node()
  end

  @spec exists?(expr(), atom()) :: boolean()
  def exists?(expr, target) do
    not is_nil(get(expr, target))
  end

  def find_single_matches(
        [pattern | patterns],
        ast,
        initial_matches \\ []
      ) do
    {_new_ast, matches} =
      Macro.prewalk(ast, initial_matches, fn node, matches ->
        if matches?(pattern.form, node) do
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

  def find_sibling_matches(patterns, ast, initial_matches \\ [])

  def find_sibling_matches(
        [p1, p2 | patterns],
        ast,
        initial_matches
      ) do
    {_new_ast, matches} =
      ast
      |> Z.zip()
      |> Z.traverse(initial_matches, fn zipper, matches ->
        sibling = Z.right(zipper)

        if matches?(p1.form, Z.node(zipper)) and not is_nil(sibling) and
             matches?(p2.form, Z.node(sibling)) do
          {zipper, [:match | matches]}
        else
          {zipper, matches}
        end
      end)

    find_sibling_matches(patterns, ast, matches)
  end

  def find_sibling_matches(_patterns, _ast, initial_matches) do
    initial_matches
  end

  def matches?({a, _, a_children}, {b, _, b_children}) do
    cond do
      a == b and is_nil(a_children) -> true
      a == b and children_matches?(a_children, b_children) -> true
      true -> false
    end
  end

  def matches?(_, _) do
    false
  end

  defp children_matches?(a, b) do
    Enum.zip(a, b)
    |> Enum.all?(fn {aa, bb} -> matches?(aa, bb) end)
  end

  defp maybe_node(input) do
    if is_nil(input), do: nil, else: Z.node(input)
  end
end
