defmodule Pacino.Parser do
  import NimbleParsec

  whitespace = ascii_string([?\r, ?\s, ?\n, ?\f], min: 1) |> ignore()

  names = ascii_string([?a..?z, ?A..?Z, ?_], min: 1)

  root_combinator = choice([names, whitespace])

  defparsec(:root, repeat(root_combinator))

  def try do
    Pacino.Parser.root("
      defmodule example do
        def my_func do
          hello
        end
      end
    ")
  end
end
