defmodule Prettiex.CLI do
  alias Prettiex.Runner
  alias Prettiex.Issue

  @parser_options [switches: [src: :string, config: :string], aliases: [s: :file, c: :file]]

  def main(args) do
    {opts, _, _} = OptionParser.parse(args, @parser_options)

    config_path = get_config_path(opts)
    paths = opts |> get_src_path() |> Path.wildcard()

    if not File.exists?(config_path) do
      raise "Missing config file at " <> config_path
    end

    {%{checks: checks}, _} = Code.eval_file(config_path)
    run_checks(checks, paths)
  end

  defp run_checks(checks, paths) do
    Enum.each(checks, fn check ->
      [{module, _}] = Code.require_file(check)

      issues =
        Enum.map(paths, fn path ->
          ast = path |> File.read!() |> Code.string_to_quoted!()
          {path, Runner.run(module, ast)}
        end)

      Enum.each(issues, fn {path, issues} ->
        Enum.each(issues, &report_issue(&1, path))
      end)

      report_totals(issues)
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

  defp get_src_path(options) do
    lib = options[:lib]

    if is_nil(lib) do
      Path.join(File.cwd!(), "lib/**/*.ex")
    else
      lib
    end
  end

  defp report_issue(%Issue{} = issue, src) do
    [line: line] = issue.info

    IO.puts(IO.ANSI.red() <> issue.name <> IO.ANSI.reset())
    IO.puts(issue.message)
    IO.puts(src <> ":" <> to_string(line))
    IO.puts("\n")
  end

  def report_totals(issues) do
    errors = to_string(length(issues))

    IO.puts("Prettiex ran and found " <> IO.ANSI.red() <> errors <> " errors" <> IO.ANSI.reset())
    IO.puts("\n")
  end
end
