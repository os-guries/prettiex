defmodule Prettiex.CLI do
  def main(args) do
    options = [switches: [file: :string], aliases: [f: :file]]
    {opts, _, _} = OptionParser.parse(args, options)

    {%{checks: checks}, _} = Code.eval_file(opts[:config])

    ast = opts[:src] |> File.read!() |> Code.string_to_quoted!()

    Enum.each(checks, fn check ->
      [{module, _}] = Code.require_file(check)

      Prettiex.Runner.run(module, ast)
      |> IO.inspect()
    end)
  end
end
