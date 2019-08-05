defmodule DataQuacker.Examples.StudentsExampleTest do
  use DataQuacker.Case, async: true

  describe "schema" do
    test "should compile the schema and expose a function with the structure" do
      assert [{TestModules.StudentsSchema, _}] = compile_file("students_example_schema.exs")

      assert %{__name__: :students} = TestModules.StudentsSchema.schema_structure(:students)
    end
  end
end
