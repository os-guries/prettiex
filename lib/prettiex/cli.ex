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
    reports =
      Enum.flat_map(checks, fn check ->
        [{module, _}] = Code.require_file(check)

        Enum.flat_map(paths, fn path ->
          ast = path |> File.read!() |> Code.string_to_quoted!()

          module
          |> Runner.run(ast)
          |> Enum.map(fn issue -> {issue, path} end)
        end)
      end)

    Enum.each(reports, fn {issue, path} -> report_issue(issue, path) end)

    report_totals(reports)
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

  defp report_issue(%Issue{} = issue, path) do
    [line: line] = issue.info

    title = " " <> issue.name <> " "
    line = String.replace(path <> ":" <> to_string(line), File.cwd!(), "")

    [
      issue.message,
      Owl.Data.tag(line, :light_black),
      "\n"
    ]
    |> Owl.Data.unlines()
    |> Owl.Box.new(padding_x: 2, padding_y: 1, title: Owl.Data.tag(title, :red_background))
    |> Owl.IO.puts()
  end

  def report_totals(issues) do
    errors = to_string(length(issues))
    error_total = IO.ANSI.red() <> errors <> " errors" <> IO.ANSI.reset()
    warning_total = IO.ANSI.yellow() <> "0 warnings" <> IO.ANSI.reset()

    IO.puts("Prettiex ran and found " <> error_total <> " and " <> warning_total)
    IO.puts("\n")
  end
end
