defmodule Examples.PublicFunctionsOnTop do
  use Prettiex

  check do
    meta do
      name "Public functions on top"
      message "Public function declarations should come first in a module"

      description """
      """
    end


    definition do
      sequence do
        pattern do
          form defp
        end

        pattern do
          skip? true
          form @spec
        end

        pattern do 
          form def
        end
      end
    end
  end
end
