defmodule DataQuacker.CSVAdapterTest do
  use ExUnit.Case, async: true

  import Mox

  alias DataQuacker.Adapters.CSV

  setup do
    {:ok,
     sample_source: [
       ["a", "b", "c"],
       ["a1", "b1", "c1"],
       ["a2", "b2", "c2"],
       ["a3", "b3", "c3"]
     ]}
  end

  describe "parse_source/2" do
    test "given a local file path, should parse the source", %{
      sample_source: [headers | rows] = sample_source
    } do
      expect(DataQuacker.MockFileManager, :stream!, fn "sample_path.csv" ->
        Stream.map(sample_source, &Enum.join(&1, ","))
      end)

      assert CSV.parse_source("sample_path.csv", local?: true) ==
               {:ok, %{headers: {:ok, headers}, rows: Enum.map(rows, &{:ok, &1})}}
    end

    test "with semicolon set as the separator given a local file path, should parse the source",
         %{sample_source: [headers | rows] = sample_source} do
      expect(DataQuacker.MockFileManager, :stream!, fn "sample_path.csv" ->
        Stream.map(sample_source, &Enum.join(&1, ";"))
      end)

      assert CSV.parse_source("sample_path.csv", local?: true, separator: ?;) ==
               {:ok, %{headers: {:ok, headers}, rows: Enum.map(rows, &{:ok, &1})}}
    end

    test "given a remote file url, should parse the source", %{
      sample_source: [headers | rows] = sample_source
    } do
      expect(DataQuacker.MockFileManager, :read_link!, fn "file_ur.com" ->
        Stream.map(sample_source, &Enum.join(&1, ","))
      end)

      assert CSV.parse_source("file_ur.com", local?: false) ==
               {:ok, %{headers: {:ok, headers}, rows: Enum.map(rows, &{:ok, &1})}}
    end

    test "with semicolon set as the separator given a remote file url, should parse the source",
         %{sample_source: [headers | rows] = sample_source} do
      expect(DataQuacker.MockFileManager, :read_link!, fn "file_ur.com" ->
        Stream.map(sample_source, &Enum.join(&1, ";"))
      end)

      assert CSV.parse_source("file_ur.com", local?: false, separator: ?;) ==
               {:ok, %{headers: {:ok, headers}, rows: Enum.map(rows, &{:ok, &1})}}
    end
  end

  #  describe "get_headers/1" do
  #    test "returns the value under the headers key, wrapped in an ':ok' tuple", %{
  #      sample_source: sample_source
  #    } do
  #      assert Identity.get_headers(sample_source) == {:ok, sample_source.headers}
  #    end
  #  end
  #
  #  describe "get_rows/1" do
  #    test "returns the value under the rows key, wrapped in an ':ok' tuple", %{
  #      sample_source: sample_source
  #    } do
  #      assert Identity.get_rows(sample_source) == {:ok, sample_source.rows}
  #    end
  #  end
  #
  #  describe "get_row/1" do
  #    test "returns the given row wrapped in an ':ok' tuple", %{sample_source: sample_source} do
  #      row = Enum.random(sample_source.rows)
  #
  #      assert Identity.get_row(row) == {:ok, row}
  #    end
  #  end
end
