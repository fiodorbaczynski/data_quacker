defmodule DataQuacker.Examples.PricingExampleTest do
  use DataQuacker.Case, async: true

  alias DataQuacker.Adapters.Identity, as: IdentityAdapter

  defmodule PricingSchema do
    use DataQuacker.Schema

    schema :pricing_example_1 do
      field :size do
        transform(fn size ->
          case Integer.parse(size) do
            {size_int, _} -> {:ok, size_int}
            :error -> {:error, "Invalid value #{size} given"}
          end
        end)

        source("Apartment/flat size (in m^2)")
      end

      field :price do
        transform(fn price ->
          case Integer.parse(price) do
            {price_int, _} -> {:ok, price_int}
            :error -> {:error, "Invalid value #{price} given"}
          end
        end)

        source("Price per 1 month")
      end
    end

    schema :pricing_example_2 do
      field :size do
        transform(&PricingSchema.parse_int_example_2/1)

        source("Apartment/flat size (in m^2)")
      end

      field :price do
        transform(&PricingSchema.parse_int_example_2/1)

        source("Price per 1 month")
      end
    end

    schema :pricing_example_3 do
      field :size do
        transform(&PricingSchema.parse_int_example_3/2)

        source(["apartment", "size"])
      end

      field :price do
        transform(&PricingSchema.parse_int_example_3/2)

        source(["price", "1"])
      end
    end

    schema :pricing_example_4 do
      row skip_if: fn %{price: price} -> is_nil(price) end do
        field :size do
          transform(&PricingSchema.parse_int_example_4/2)

          source(["apartment", "size"])
        end

        field :duration do
          virtual_source(1)
        end

        field :price do
          transform(&PricingSchema.parse_int_example_4/2)

          source(["price", "1"])
        end
      end

      row do
        field :size do
          transform(&PricingSchema.parse_int_example_4/2)

          source(["apartment", "size"])
        end

        field :duration do
          virtual_source(3)
        end

        field :price do
          transform(&PricingSchema.parse_int_example_4/2)

          source(["price", "3"])
        end
      end
    end

    schema :pricing_example_5 do
      row skip_if: fn %{price: price} -> is_nil(price) end do
        field :size do
          transform(&PricingSchema.parse_int_example_5/2)

          source(["apartment", "size"])
        end

        field :duration do
          virtual_source(1)
        end

        field :price do
          transform(&PricingSchema.replace_commas/1)
          transform(&PricingSchema.parse_decimal/2)

          source(["price", "1"])
        end
      end

      row do
        field :size do
          transform(&PricingSchema.parse_int_example_5/2)

          source(["apartment", "size"])
        end

        field :duration do
          virtual_source(3)
        end

        field :price do
          transform(&PricingSchema.replace_commas/1)
          transform(&PricingSchema.parse_decimal/2)

          source(["price", "3"])
        end
      end
    end

    def parse_int_example_2(str) do
      case Integer.parse(str) do
        {int, _} -> {:ok, int}
        :error -> {:error, "Invalid value #{str} given"}
      end
    end

    def parse_int_example_3(str, %{metadata: metadata, source_row: source_row}) do
      case Integer.parse(str) do
        {int, _} ->
          {:ok, int}

        :error ->
          {:error,
           "Error processing #{elem(metadata, 0)} #{elem(metadata, 1)} in row #{source_row}; '#{
             str
           }' given"}
      end
    end

    def parse_int_example_4("", _), do: {:ok, nil}

    def parse_int_example_4(str, %{metadata: metadata, source_row: source_row}) do
      case Integer.parse(str) do
        {int, _} ->
          {:ok, int}

        :error ->
          {:error,
           "Error processing #{elem(metadata, 0)} #{elem(metadata, 1)} in row #{source_row}; '#{
             str
           }' given"}
      end
    end

    def parse_int_example_5("", _), do: {:ok, nil}

    def parse_int_example_5(str, %{metadata: metadata, source_row: source_row}) do
      case Integer.parse(str) do
        {int, _} ->
          {:ok, int}

        :error ->
          {:error,
           "Error processing #{elem(metadata, 0)} #{elem(metadata, 1)} in row #{source_row}; '#{
             str
           }' given"}
      end
    end

    def replace_commas(str) do
      {:ok, String.replace(str, ",", ".")}
    end

    def parse_decimal("", _), do: {:ok, nil}

    def parse_decimal(str, %{metadata: metadata, source_row: source_row}) do
      case Decimal.parse(str) do
        {:ok, decimal} ->
          {:ok, decimal}

        :error ->
          {:error,
           "Error processing #{elem(metadata, 0)} #{elem(metadata, 1)} in row #{source_row}; '#{
             str
           }' given"}
      end
    end
  end

  describe "pricing example" do
    @tag :integration
    test "should parse sample data given the pricing example 1 schema" do
      assert {:ok, [row1, row2]} =
               DataQuacker.parse(
                 %{
                   headers: ["Apartment/flat size (in m^2)", "Price per 1 month"],
                   rows: [
                     ["40", "1000"],
                     ["50", "1100"]
                   ]
                 },
                 PricingSchema.schema_structure(:pricing_example_1),
                 nil,
                 adapter: IdentityAdapter
               )

      assert row1 == {:ok, %{size: 50, price: 1100}}
      assert row2 == {:ok, %{size: 40, price: 1000}}
    end

    @tag :integration
    test "should parse sample data given the pricing example 2 schema" do
      assert {:ok, [row1, row2]} =
               DataQuacker.parse(
                 %{
                   headers: ["Apartment/flat size (in m^2)", "Price per 1 month"],
                   rows: [
                     ["40", "1000"],
                     ["50", "1100"]
                   ]
                 },
                 PricingSchema.schema_structure(:pricing_example_2),
                 nil,
                 adapter: IdentityAdapter
               )

      assert row1 == {:ok, %{size: 50, price: 1100}}
      assert row2 == {:ok, %{size: 40, price: 1000}}
    end

    @tag :integration
    test "should parse sample data given the pricing example 3 schema" do
      assert {:error, [row1, row2, row3, row4]} =
               DataQuacker.parse(
                 %{
                   headers: ["Apartment or flat size", "Price for 1 month"],
                   rows: [
                     ["40", "1000"],
                     ["50", "1100"],
                     ["50", "a lot of $$$"],
                     ["huge", "1000000"]
                   ]
                 },
                 PricingSchema.schema_structure(:pricing_example_3),
                 nil,
                 adapter: IdentityAdapter
               )

      assert row1 == {:error, "Error processing field size in row 4; 'huge' given"}
      assert row2 == {:error, "Error processing field price in row 3; 'a lot of $$$' given"}
      assert row3 == {:ok, %{size: 50, price: 1100}}
      assert row4 == {:ok, %{size: 40, price: 1000}}
    end

    @tag :integration
    test "should parse sample data given the pricing example 4 schema" do
      assert {:ok, [row1, row2, row3, row4, row5]} =
               DataQuacker.parse(
                 %{
                   headers: ["Apartment or flat size", "Price for 1 month", "Price per 3 months"],
                   rows: [
                     ["40", "1000", "2800"],
                     ["50", "1100", "3000"],
                     ["60", "", "3600"]
                   ]
                 },
                 PricingSchema.schema_structure(:pricing_example_4),
                 nil,
                 adapter: IdentityAdapter
               )

      assert row1 == {:ok, %{duration: 3, price: 3600, size: 60}}
      assert row2 == {:ok, %{duration: 3, price: 3000, size: 50}}
      assert row3 == {:ok, %{duration: 1, price: 1100, size: 50}}
      assert row4 == {:ok, %{duration: 3, price: 2800, size: 40}}
      assert row5 == {:ok, %{duration: 1, price: 1000, size: 40}}
    end

    @tag :integration
    test "should parse sample data given the pricing example 5 schema" do
      assert {:ok, [row1, row2, row3, row4, row5]} =
               DataQuacker.parse(
                 %{
                   headers: ["Apartment or flat size", "Price for 1 month", "Price per 3 months"],
                   rows: [
                     ["40", "999,99", "2799,99"],
                     ["50", "1099,99", "2999,99"],
                     ["60", "", "3599,99"]
                   ]
                 },
                 PricingSchema.schema_structure(:pricing_example_5),
                 nil,
                 adapter: IdentityAdapter
               )

      assert row1 == {:ok, %{duration: 3, price: Decimal.new("3599.99"), size: 60}}
      assert row2 == {:ok, %{duration: 3, price: Decimal.new("2999.99"), size: 50}}
      assert row3 == {:ok, %{duration: 1, price: Decimal.new("1099.99"), size: 50}}
      assert row4 == {:ok, %{duration: 3, price: Decimal.new("2799.99"), size: 40}}
      assert row5 == {:ok, %{duration: 1, price: Decimal.new("999.99"), size: 40}}
    end
  end
end
