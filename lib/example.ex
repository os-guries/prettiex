defmodule Example do
  use Prettiex

  check do
    meta do
      name "Example Check"
      message "Some useful check has failed. Good luck."
      description "This is just a DSL test, really."
    end

    definition do
      sequence do
        pattern @params
        pattern test _
      end
    end
  end
end
