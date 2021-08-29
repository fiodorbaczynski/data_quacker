defmodule DataQuacker.Examples.PondExampleTest do
  use DataQuacker.Case, async: true

  alias DataQuacker.Adapters.Identity

  defmodule PondSchema do
    use DataQuacker.Schema

    schema :pond_example_1 do
      field :type do
        source("type")
      end

      field :colour do
        source(~r/colou?r/i)
      end

      field :age do
        source("age")
      end
    end

    schema :pond_example_2 do
      field :type do
        validate(fn type -> type in ["Mallard", "Domestic", "Mandarin"] end)

        source("type")
      end

      field :colour do
        source(~r/colou?r/i)
      end

      field :age do
        transform(fn age_str ->
          case Integer.parse(age_str) do
            {age_int, _} -> {:ok, age_int}
            :error -> :error
          end
        end)

        source("age")
      end
    end
  end

  describe "pond example" do
    @tag :integration
    test "should parse sample data given the pond example 1 schema" do
      assert {:ok, [row1, row2, row3]} =
               DataQuacker.parse(
                 %{
                   headers: ["Type", "Colour", "Age"],
                   rows: [
                     ["Mallard", "green", "3"],
                     ["Domestic", "white", "2"],
                     ["Mandarin", "multi-coloured", "4"]
                   ]
                 },
                 PondSchema.schema_structure(:pond_example_1),
                 nil,
                 adapter: Identity
               )

      assert row1 == {:ok, %{type: "Mandarin", colour: "multi-coloured", age: "4"}}
      assert row2 == {:ok, %{type: "Domestic", colour: "white", age: "2"}}
      assert row3 == {:ok, %{type: "Mallard", colour: "green", age: "3"}}
    end

    @tag :integration
    test "should parse sample data given the pond example 2 schema" do
      assert {:error, [row1, row2, row3, row4, row5]} =
               DataQuacker.parse(
                 %{
                   headers: ["Type", "Colour", "Age"],
                   rows: [
                     ["Mallard", "green", "3"],
                     ["Domestic", "white", "2"],
                     ["Mandarin", "multi-coloured", "4"],
                     ["Mystery", "golden", "100"],
                     ["Black", "black", "Infinity"]
                   ]
                 },
                 PondSchema.schema_structure(:pond_example_2),
                 nil,
                 adapter: Identity
               )

      assert row1 == :error
      assert row2 == :error
      assert row3 == {:ok, %{type: "Mandarin", colour: "multi-coloured", age: 4}}
      assert row4 == {:ok, %{type: "Domestic", colour: "white", age: 2}}
      assert row5 == {:ok, %{type: "Mallard", colour: "green", age: 3}}
    end
  end
end
