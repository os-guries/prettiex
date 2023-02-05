defmodule Examples.PreferAliasOverModule do
  use Prettiex

  check do
    meta do
      name "Prefer alias over __MODULE__"
      message "Instead of using __MODULE__, add an alias and use it."

      description """
      Prefer to use an alias instead of calling __MODULE__. This improves readability
      by using explicit names instead of requiring the reviewers to keep track of
      what is the current module.
      """
    end

    definition do
      all do
        pattern do
          skip? true
          form alias __MODULE__
        end

        pattern do
          form __MODULE__
        end
      end
    end
  end
end

