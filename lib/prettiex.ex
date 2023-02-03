defmodule Prettiex do
  use Spark.Dsl,
    default_extensions: [
      extensions: [Prettiex.Check]
    ]
end
