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
    |> Enum.all?(fn {aa, bb} -> match?(aa, bb) end)
  end

  defp maybe_node(input) do
    if is_nil(input), do: nil, else: Z.node(input)
  end
end
