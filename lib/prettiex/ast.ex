defmodule Prettiex.AST do
  alias Sourceror.Zipper, as: Z

  def find(pattern, ast) do
    ast
    |> Z.zip()
    |> Z.find(&matches_form?(pattern.form, &1))
  end

  def match_all(patterns, ast) do
    patterns
    |> find_matches(ast)
    |> Enum.all?(&(&1 == :match))
  end

  def match_sequence([p1, p2 | ps], ast) do
    with {:node, node} when not is_nil(node) <- {:node, find(p1, ast)},
         {:right, right} when not is_nil(right) <- {:right, node |> Z.right() |> maybe_node()} do
      if matches_form?(p2.form, right) do
        true and match_sequence(ps, ast)
      else
        false
      end
    end
  end

  def match_sequence([pattern], ast) do
    not is_nil(find(pattern, ast))
  end

  def match_sequence([], _ast), do: true

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
      pattern
      |> find(ast)
      |> on_match.(pattern)
    end)
    |> Enum.filter(&(&1 != :skip))
  end

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
