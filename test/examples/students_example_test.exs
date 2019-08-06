defmodule DataQuacker.Examples.StudentsExampleTest do
  use DataQuacker.Case, async: true

  alias DataQuacker.Adapters.Identity, as: IdentityAdapter

  defmodule StudentsSchema do
    use DataQuacker.Schema

    schema :students do
      field :full_name do
        transform(fn %{first_name: first_name, last_name: last_name} ->
          {:ok, "#{first_name} #{last_name}"}
        end)

        field :first_name do
          source("first name")
        end

        field :last_name do
          source("last name")
        end
      end

      field :age do
        transform(fn age ->
          case Integer.parse(age) do
            {age_int, _} -> {:ok, age_int}
            :error -> {:error, "Invalid value #{age} given"}
          end
        end)

        source("age")
      end

      field :favourite_subject do
        validate(fn subj, context ->
          case subj in context.support_data.valid_subjects do
            true ->
              :ok

            false ->
              {:error,
               "Invalid favourite subject in row ##{context.source_row}, must be one of #{
                 inspect(context.support_data.valid_subjects)
               }"}
          end
        end)

        source("favourite subject")
      end
    end
  end

  describe "students example" do
    @tag :integration
    test "should parse sample data given the students schema" do
      assert {:error, [row4, row3, row2, row1]} =
               DataQuacker.parse(
                 %{
                   headers: ["First name", "Last name", "Age", "Favourite subject"],
                   rows: [
                     ["John", "Smith", "19", "Maths"],
                     ["Adam", "Johnson", "18", "Physics"],
                     ["Quackers", "the Duck", "1", "Programming"],
                     ["Mat", "Savage", "100", "None"]
                   ]
                 },
                 StudentsSchema.schema_structure(:students),
                 %{valid_subjects: ["Maths", "Physics", "Programming"]},
                 adapter: IdentityAdapter
               )

      assert row1 == {:ok, %{age: 19, favourite_subject: "Maths", full_name: "John Smith"}}
      assert row2 == {:ok, %{age: 18, favourite_subject: "Physics", full_name: "Adam Johnson"}}

      assert row3 ==
               {:ok, %{age: 1, favourite_subject: "Programming", full_name: "Quackers the Duck"}}

      assert row4 ==
               {:error,
                "Invalid favourite subject in row #4, must be one of [\"Maths\", \"Physics\", \"Programming\"]"}
    end
  end
end
