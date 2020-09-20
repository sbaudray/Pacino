defmodule Pacino.Parser do
  import NimbleParsec

  @operators ~w[ + * - ]

  whitespace = ascii_string([?\r, ?\s, ?\n, ?\f], min: 1) |> ignore()

  operator = choice(for operator <- @operators, do: string(operator)) |> unwrap_and_tag(:operator)

  number = ascii_string([?0..?9], min: 1) |> unwrap_and_tag(:number)

  name = ascii_string([?a..?z, ?A..?Z, ?_], min: 1)

  defparsec(
    :binary_expr,
    choice([
      number
      |> ignore(whitespace)
      |> concat(operator)
      |> ignore(whitespace)
      |> concat(parsec(:binary_expr))
      |> tag(:binary_expr),
      number
    ])
  )

  root_combinator = parsec(:binary_expr)

  defparsec(:root, repeat(root_combinator))

  def ast(tokens) do
    walk(tokens)
  end

  def walk({:ok, list, _rest, _dunno, _lines, _length}) do
    walk(list, [])
  end

  def walk([current | rest], ast) do
    node = get_node(current)
    walk(rest, [node | ast])
  end

  def walk([], [ast]) do
    ast
  end

  def get_node({:binary_expr, [left, operator, right]}) do
    %{
      kind: "BinaryExpression",
      left: get_node(left),
      operator: get_node(operator),
      right: get_node(right)
    }
  end

  def get_node({:number, value}) do
    %{
      kind: "NumberLiteral",
      value: value
    }
  end

  def get_node({:operator, value}) do
    value
  end

  def print() do
    root("1 + 2 * 3 - 9")
    |> ast
    |> visit
  end

  def visit(%{kind: "BinaryExpression", left: left, operator: operator, right: right}) do
    "#{visit(left)} #{operator} #{visit(right)}"
  end

  def visit(%{kind: "NumberLiteral", value: value}) do
    value
  end
end
