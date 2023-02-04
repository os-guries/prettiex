defmodule Prettiex.Runner do
  alias Prettiex.Check.All
  alias Prettiex.Check.Definition
  alias Prettiex.Check.Meta
  alias Prettiex.Issue
  alias Prettiex.Check.Sequence
  alias Prettiex.AST

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
    matches? = patterns |> AST.find_single_matches(ast) |> Enum.all?(&(&1 == :match))

    if matches? do
      [emit_issue!(check)]
    else
      []
    end
  end

  defp interpret(check, %Sequence{patterns: patterns}, ast) do
    matches? = patterns |> AST.find_sibling_matches(ast) |> Enum.any?(&(&1 == :match))

    if matches? do
      [emit_issue!(check)]
    else
      []
    end
  end

  defp interpret(_check, _node, _ast) do
    []
  end

  defp emit_issue!(%{entities: [%Meta{} = meta | _]}) do
    %Issue{name: meta.name, message: meta.message}
  end
end
