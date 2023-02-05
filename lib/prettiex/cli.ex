defmodule Prettiex.CLI do
  alias Prettiex.Runner
  alias Prettiex.Issue

  def main(args) do
    options = [switches: [src: :string, config: :string], aliases: [s: :file, c: :file]]
    {opts, _, _} = OptionParser.parse(args, options)

    config = get_config_path(opts)
    paths = Path.wildcard(opts[:src])

    try do
      {%{checks: checks}, _} = Code.eval_file(config)
      run_checks(checks, paths)
    rescue
      _ -> raise "Missing config file"
    end
  end

  defp run_checks(checks, paths) do
    Enum.each(checks, fn check ->
      [{module, _}] = Code.require_file(check)

      Enum.each(paths, fn path ->
        ast = path |> File.read!() |> Code.string_to_quoted!()

        module
        |> Runner.run(ast)
        |> Enum.each(fn issue -> report_issue(issue, path) end)
      end)
    end)
  end

  defp get_config_path(options) do
    config = options[:config]

    if config do
      config
    else
      Path.join(File.cwd!(), ".prettiex.exs")
    end
  end

  defp report_issue(%Issue{} = issue, src) do
    [line: line] = issue.info

    IO.puts(IO.ANSI.red() <> issue.name <> IO.ANSI.reset())
    IO.puts(issue.message)
    IO.puts(src <> ":" <> to_string(line))
    IO.puts("\n")
  end
end
