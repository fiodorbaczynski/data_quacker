defmodule TestModules.StudentsSchema do
  use DataQuacker.Schema

  schema :students do
    field :full_name do
      transform(fn %{first_name: first_name, last_name: last_name} ->
        {:ok, "#{first_name} #{last_name}"}
      end)

      field :first_name do
        source("first name")
      end

      field :first_name do
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
      validate(fn subj -> subj in ["Maths", "Physics", "Programming"] end)

      source("favourite subject")
    end
  end
end
