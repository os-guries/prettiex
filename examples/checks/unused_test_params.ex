defmodule Examples.UnusedTestParams do
  use Prettiex

  check do
    meta do
      name "Unused Test @params"
      message "@params has been defined before a `test/2` call."

      description """
      It looks like you meant to use `test_with_params/2` but called `test/2` instead.
      If this is intentional, consider renaming the attribute to something more descriptive.
      """
    end

    definition do
      sequence do
        pattern @params
        pattern test _
      end
    end
  end
end
