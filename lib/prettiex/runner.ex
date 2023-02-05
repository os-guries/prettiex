defmodule Prettiex.Runner do
  alias Prettiex.AST
  alias Prettiex.Check.All
  alias Prettiex.Check.Definition
  alias Prettiex.Check.Meta
  alias Prettiex.Check.Sequence
  alias Prettiex.Issue

  def run(module, ast) do
    check = module.spark_dsl_config[[:check]]

    Enum.flat_map(check.entities, &interpret(check, &1, ast))
  end

  defp interpret(_check, %Meta{}, _ast) do
    []
  end

  defp interpret(check, %Definition{all: all, sequence: sequence, alternative: alternative}, ast) do
    Enum.flat_map(sequence ++ all ++ alternative, &interpret(check, &1, ast))
  end

  defp interpret(check, %All{patterns: patterns}, ast) do
    if AST.match_all(patterns, ast) do
      [emit_issue!(check)]
    else
      []
    end
  end

  defp interpret(check, %Sequence{patterns: patterns}, ast) do
    if AST.match_sequence(patterns, ast) do
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
