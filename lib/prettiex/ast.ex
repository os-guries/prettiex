defmodule Prettiex.AST do
  alias Sourceror.Zipper, as: Z

  def find(pattern, ast) do
    ast
    |> Z.zip()
    |> Z.find(&matches_form?(pattern.form, &1))
  end

  def match_all(patterns, ast) do
    matches = find_matches(patterns, ast)

    if Enum.all?(matches, &is_match/1) do
      Enum.find(matches, &is_match/1)
    end
  end

  # {:match, node} | nil
  def match_sequence([p1, p2 | ps], ast) do
    with node when not is_nil(node) <- find(p1, ast),
         right when not is_nil(right) <- node |> Z.right() |> maybe_node() do
      if matches_form?(p2.form, right) or p2.skip? do
        if match_sequence(ps, ast) do
          {:match, maybe_node(node)}
        end
      else
        nil
      end
    else
      _ -> nil
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
        pattern.skip? -> {:skip_match, maybe_node(match)}
        true -> {:match, maybe_node(match)}
      end
    end

    Enum.map(patterns, fn pattern ->
      pattern
      |> find(ast)
      |> on_match.(pattern)
    end)
    |> Enum.filter(&(&1 != :skip))
  end

  def matches_form?({form_atom, _, form_args} = form, {node_atom, _, _} = node) do
    cond do
      form_atom != node_atom ->
        false

      is_nil(form_args) ->
        true

      true ->
        next_form = form |> Z.zip() |> Z.next()
        next_node = node |> Z.zip() |> Z.next() |> maybe_node()

        cond do
          is_end?(next_form) -> true
          is_nil(next_node) -> false
          true -> matches_form?(maybe_node(next_form), next_node)
        end
    end
  end

  def matches_form?(a, b) do
    a == b
  end

  defp maybe_node(input) do
    if is_nil(input), do: nil, else: Z.node(input)
  end

  defp is_match({:match, _}), do: true
  defp is_match(_), do: false

  defp is_end?({_, meta}), do: meta == :end
end
