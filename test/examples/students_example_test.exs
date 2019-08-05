defmodule DataQuacker.Examples.StudentsExampleTest do
  use DataQuacker.Case, async: true

  alias DataQuacker.Adapters.Identity, as: IdentityAdapter

  import DataQuacker.Factory

  setup do
    [{TestModules.StudentsSchema, _}] = compile_file("students_example_schema.exs")
  end

  describe "students example" do
    setup do
      students = build_list(10, :student)

      {:ok, students: students}
    end

    @tag :integration
    test "should parse sample data given the students schema", %{students: students} do
      {_result_status, _result_rows} =
        DataQuacker.parse(
          %{
            headers: ["First name", "Last name", "Age", "Favourite subject"],
            rows: students
          },
          TestModules.StudentsSchema.schema_structure(:students),
          %{valid_subjects: ["Maths", "Physics", "Programming"]},
          adapter: IdentityAdapter
        )
    end
  end
end
