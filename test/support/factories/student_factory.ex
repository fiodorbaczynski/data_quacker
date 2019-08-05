defmodule DataQuacker.StudentFactory do
  use ExMachina

  defmacro __using__(_opts) do
    quote do
      def student_factory(_opts) do
        [
          sequence(:student_first_name, &"first-name-#{&1}"),
          sequence(:student_last_name, &"last-name-#{&1}"),
          "#{Enum.random(0..100)}",
          Enum.random(subjects())
        ]
      end

      defp subjects() do
        [
          "Maths",
          "Physics",
          "Programming",
          "Electrical engineering",
          "Mechanical engineering",
          "Civil engineering",
          "Computer science",
          "Biology",
          "Chemistry"
        ]
      end
    end
  end
end
