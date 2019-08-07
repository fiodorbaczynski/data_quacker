defmodule DataQuacker.IdentityAdapterTest do
  use ExUnit.Case, async: true

  alias DataQuacker.Adapters.Identity

  setup do
    {:ok,
     sample_source: %{
       headers: ["a", "b", "c"],
       rows: [
         ["a1", "b1", "c1"],
         ["a2", "b2", "c2"],
         ["a3", "b3", "c3"]
       ]
     }}
  end

  describe "parse_source/2" do
    test "returns the source as-is, wrapped in an ':ok' tuple", %{sample_source: sample_source} do
      assert Identity.parse_source(sample_source, []) == {:ok, sample_source}
    end
  end

  describe "get_headers/1" do
    test "returns the value under the headers key, wrapped in an ':ok' tuple", %{
      sample_source: sample_source
    } do
      assert Identity.get_headers(sample_source) == {:ok, sample_source.headers}
    end
  end

  describe "get_rows/1" do
    test "returns the value under the rows key, wrapped in an ':ok' tuple", %{
      sample_source: sample_source
    } do
      assert Identity.get_rows(sample_source) == {:ok, sample_source.rows}
    end
  end

  describe "get_row/1" do
    test "returns the given row wrapped in an ':ok' tuple", %{sample_source: sample_source} do
      row = Enum.random(sample_source.rows)

      assert Identity.get_row(row) == {:ok, row}
    end
  end
end
