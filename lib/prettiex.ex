defmodule Prettiex do
  use Spark.Dsl,
    default_extensions: [
      extensions: [Prettiex.Check]
    ]

  defmodule Issue do
    defstruct [:name, :message, :info]
  end

  # TODO: Accept `matcher_fun` with arity = 2 and pass an accumulator around
  # for that case
  def collect(ast, matcher_fun) when is_function(matcher_fun) do
    {_ast, issues} =
      Macro.prewalk(ast, [], fn node, issues ->
        case matcher_fun.(node) do
          :skip -> {nil, issues}
          :continue -> {node, issues}
          %Issue{} = issue -> {node, [issue | issues]}
        end
      end)

    issues
  end
end
