defmodule Mix.Tasks.Prettiex do
  use Mix.Task

  def run(argv) do
    Prettiex.CLI.main(argv)
  end
end
