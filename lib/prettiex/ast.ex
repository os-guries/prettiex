defmodule Prettiex.AST do
  alias Sourceror.Zipper, as: Z

  @typep expr :: {atom, any(), atom | [expr()]}

  def find_matches(
        patterns,
        ast
      ) do
    on_match = fn match, pattern ->
      cond do
        is_nil(match) -> :skip
        pattern.skip? -> :skip_match
        true -> :match
      end
    end

    Enum.map(patterns, fn pattern ->
      ast
      |> Z.zip()
      |> Z.find(&matches_form?(pattern.form, &1))
      |> on_match.(pattern)
    end)
    |> Enum.filter(&(&1 != :skip))
  end

  def match_all(patterns, ast) do
    patterns
    |> find_matches(ast)
    |> Enum.all?(&(&1 == :match))
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

  def matches?(a, b) do
    cond do
      node_atom(a) == node_atom(b) and is_nil(node_args(a)) -> true
      node_atom(a) == node_atom(b) and args_match?(node_args(a), node_args(b)) -> true
      true -> false
    end
  end

  def matches?(_, _) do
    false
  end

  defp args_match?(a, b) when is_list(a) and is_list(b) do
    Enum.zip(a, b)
    |> Enum.all?(fn {aa, bb} -> matches?(aa, bb) end)
  end

  defp args_match?(a, b), do: a == b

  defp node_atom({atom, _, _}), do: atom
  defp node_args({_, _, args}), do: args

  defp maybe_node(input) do
    if is_nil(input), do: nil, else: Z.node(input)
  end

  def matches_form?({form_atom, _, form_args}, {node_atom, _meta, node_args}) do
    form_atom == node_atom and (is_nil(form_args) or form_args == node_args)
  end

  def matches_form?(a, b) do
    a == b
  end
end
