defmodule Prettiex.ASTTest do
  use ExUnit.Case

  alias Prettiex.AST
  alias Prettiex.Check.Pattern

  describe "match_all/2" do
    test "matches single pattern" do
      pattern = %Pattern{
        skip?: false,
        form:
          quote do
            defp function do
            end
          end
      }

      ast =
        quote do
          defmodule Something do
            defp function do
            end
          end
        end

      assert AST.match_all([pattern], ast)
    end

    test "matches multiple patterns" do
      patterns = [
        %Pattern{
          skip?: false,
          form: {:+, [], [1, 1]}
        },
        %Pattern{
          skip?: false,
          form: {:defp, [], nil}
        }
      ]

      ast =
        quote do
          defmodule Something do
            defp function do
              1 + 1
            end
          end
        end

      assert AST.match_all(patterns, ast)
    end

    test "does not match when pattern is skipped" do
      patterns = [
        %Pattern{
          skip?: true,
          form:
            quote do
              import Good
            end
        },
        %Pattern{
          skip?: false,
          form: {:import, [], nil}
        }
      ]

      ast =
        quote do
          defmodule Something do
            import Good

            defp function do
              1 + 1
            end
          end
        end

      assert [:skip_match, :match] = AST.find_matches(patterns, ast)
      refute AST.match_all(patterns, ast)
    end
  end

  describe "find_sibling_matches" do
    test "matches sequence patterns" do
      patterns = [
        %Pattern{form: {:def, [], nil}},
        %Pattern{form: {:defp, [], nil}}
      ]

      ast =
        quote do
          defmodule Test do
            def public do
            end

            defp private do
            end
          end
        end

      assert AST.match_sequence(patterns, ast)
    end

    test "does not match non-adjacent patterns" do
      patterns = [
        %Pattern{form: {:def, [], nil}},
        %Pattern{form: {:defp, [], nil}}
      ]

      ast =
        quote do
          defmodule Test do
            def public do
            end

            @spec private() :: nil
            defp private do
            end
          end
        end

      refute AST.match_sequence(patterns, ast)
    end

    test "skips maintain the sequence" do
      patterns = [
        %Pattern{form: {:def, [], nil}},
        %Pattern{skip?: true, form: {:@, [], [{:spec, [], nil}]}},
        %Pattern{form: {:defp, [], nil}}
      ]

      ast =
        quote do
          defmodule Test do
            def public do
            end

            @spec private() :: nil
            defp private do
            end
          end
        end

      assert AST.match_sequence(patterns, ast)
    end

    test "skips are optional to appear in sequence" do
      patterns = [
        %Pattern{form: {:def, [], nil}},
        %Pattern{skip?: true, form: {:@, [], [{:spec, [], nil}]}},
        %Pattern{form: {:defp, [], nil}}
      ]

      ast =
        quote do
          defmodule Test do
            def public do
            end

            defp private do
            end
          end
        end

      assert AST.match_sequence(patterns, ast)
    end

    test "matches single patterns" do
      patterns = [
        %Pattern{form: {:def, [], nil}}
      ]

      ast =
        quote do
          defmodule Test do
            def public do
            end

            @spec private() :: nil
            defp private do
            end
          end
        end

      assert AST.match_sequence(patterns, ast)
    end
  end

  describe "find_matches/2" do
    test "matches pattern" do
      pattern = %Pattern{
        skip?: false,
        form:
          quote do
            defp function do
            end
          end
      }

      ast =
        quote do
          defmodule Something do
            defp function do
            end
          end
        end

      assert [:match] == AST.find_matches([pattern], ast)
    end

    test "skips matching pattern" do
      pattern = %Pattern{
        skip?: true,
        form:
          quote do
            defp function do
            end
          end
      }

      ast =
        quote do
          defmodule Something do
            defp function do
            end
          end
        end

      assert [:skip_match] == AST.find_matches([pattern], ast)
    end

    test "skips unmatching" do
      pattern = %Pattern{
        skip?: false,
        form:
          quote do
            defp function do
            end
          end
      }

      ast =
        quote do
          defmodule Something do
            def function do
            end
          end
        end

      assert [] == AST.find_matches([pattern], ast)
    end

    test "matches multiple patterns ss" do
      patterns = [
        %Pattern{
          form:
            quote do
              import Other
            end
        }
      ]

      ast =
        quote do
          defmodule Something do
            import Other

            def function do
            end
          end
        end

      assert [:match] == AST.find_matches(patterns, ast)
    end

    test "matches multiple patterns" do
      patterns = [
        %Pattern{
          form:
            quote do
              def function do
              end
            end
        },
        %Pattern{
          form:
            quote do
              import Other
            end
        }
      ]

      ast =
        quote do
          defmodule Something do
            import Other

            def function do
            end
          end
        end

      assert [:match, :match] == AST.find_matches(patterns, ast)
    end
  end
end
