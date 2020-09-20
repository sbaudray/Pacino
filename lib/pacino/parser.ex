defmodule Pacino.Parser do
  import NimbleParsec

  @operators ~w[ + * - ]
  @keywords ~w[def do end]

  whitespace = ascii_string([?\r, ?\s, ?\n, ?\f], min: 1) |> ignore()

  operator = choice(for operator <- @operators, do: string(operator)) |> unwrap_and_tag(:operator)

  number = ascii_string([?0..?9], min: 1) |> unwrap_and_tag(:number)

  keyword = choice(for keyword <- @keywords, do: string(keyword))

  identifier =
    lookahead_not(keyword)
    |> ascii_string([?a..?z, ?A..?Z, ?_], min: 1)
    |> unwrap_and_tag(:identifier)

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

  expr = choice([parsec(:binary_expr), identifier])

  function =
    string("def")
    |> ignore()
    |> concat(whitespace)
    |> concat(identifier)
    |> concat(whitespace)
    |> concat(string("do") |> ignore)
    |> concat(repeat(whitespace |> concat(expr)) |> tag(:body))
    |> concat(whitespace)
    |> concat(string("end") |> ignore)
    |> tag(:function)

  root_combinator = choice([whitespace, expr, function])

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

  def get_node({:function, [identifier, body]}) do
    %{
      kind: "FunctionDeclaration",
      identifier: get_node(identifier),
      body: get_node(body)
    }
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

  def get_node({:identifier, value}) do
    value
  end

  def get_node({:body, body}) do
    %{
      kind: "BlockStatement",
      body: Enum.map(body, &get_node/1)
    }
  end

  def test_string do
    "def test do
      1 + 2 * 3 - 9
      mama
    end"
  end

  def test do
    root(test_string())
  end

  def print(content \\ test_string()) do
    printable =
      root(content)
      |> ast
      |> visit

    {:ok, file} = File.open("test.js", [:write])
    IO.binwrite(file, printable)
    File.close(file)

    printable
  end

  def print_file(path) do
    {:ok, content} = File.read(path)
    print(content)
  end

  def visit(%{kind: "BinaryExpression", left: left, operator: operator, right: right}) do
    "#{visit(left)} #{operator} #{visit(right)}"
  end

  def visit(%{kind: "NumberLiteral", value: value}) do
    value
  end

  def visit(%{kind: "BlockStatement", body: body}) do
    Enum.map(body, &visit/1) |> Enum.join("\n\s\s")
  end

  def visit(%{kind: "FunctionDeclaration", identifier: identifier, body: body}) do
    "function #{identifier}() {\n\s\s#{visit(body)}\n}"
  end

  def visit(literal) do
    literal
  end
end
