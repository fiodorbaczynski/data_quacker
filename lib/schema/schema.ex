defmodule DataQuacker.Schema do
  @moduledoc ~S"""
  Defines macros for creating data schemas
  which represents a mapping from the source to the desired output.

  Note: To use the macros you have to put `use DataQuacker.Schema` in the desired module.

  A schema can be defined to represent the structure of an arbitrarily nested map or list of maps.
  This is done with the `schema/2`, `row/2` and `field/3` macros.
  Additionally, there are two special macros: `validate/1` and `transform/1`.
  Lastly, the `source/1` and `virtual_source/1` macros are used
  to define the data which should be inserted in a particular field.
  These allow for validation and transformation to be performed
  on a specific subset of the output data.

  Note: the `row/2` and `field/3` macros represent the *output* structure,
  while the `source/1` and `virtual_source/1` macros reference the input data.
  Since both the input and the output can be said to have rows,
  the term "source row" is used in the documentation to denote a row in the input data.
  The term "row" is used to denote a row in the output.

  All of the structure-defining macros take a block as their last argument
  which can be thought of as their "body". The `schema/2` and `field/2` macros
  also take a name as their first argument, and `row/2` and `field/3`
  take a keyword list of options as their first and second argument respectively.

  More information can be found in the documentation for the specific macros.

  To understand how this works in practice let's take a look at an example:

  Suppose we have a table of students in the form of a CSV file, which looks like this:

  | First name | Last name | Age | Favourite subject |
  |:----------:|:---------:|:---:|:-----------------:|
  | John       | Smith     | 19  | Maths             |
  | Adam       | Johnson   | 18  | Physics           |
  | Quackers   | the Duck  | 1   | Programming       |

  Also suppose our desired output is a list of tuples with maps with the following structure

  ```elixir
  {:ok, %{
    first_name: "...",
    last_name: "...",
    age: "...",
    favourite_subject: "..."
  }}
  ```

  The mapping from the table to the list of maps can be represented as follows:

  ```elixir
  defmodule StudentsSchema do
    use DataQuacker.Schema

    schema :students do
      field :first_name do
        source("first name")
      end

      field :first_name do
        source("last name")
      end

      field :age do
        source("age")
      end

      field :favourite_subject do
        source("favourite subject")
      end
    end
  end
  ```

  This looks great (I hope!), but realistically we would like age to be an Integer,
  and favourite subject to be somehow validated. This can be achieved by modifying the previous schema, like this:

  ```elixir
  defmodule StudentsSchema do
    use DataQuacker.Schema

    schema :students do
      field :first_name do
        source("first name")
      end

      field :first_name do
        source("last name")
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
        validate(fn subj -> subj in ["Maths, "Physics, "Programming"] end)

        source("favourite subject")
      end
    end
  end
  ```

  Now our result will be a list of maps, like:
  ```elixir
  %{
    # ...
    {:ok, %{age: 123, ...},
    # ...
  }
  ```

  However if, for example, an invalid age is given,
  the entire row where the error occurred will result in the following tuple:
  `{:error, "Invalid value blabla given"}`

  Great, but what if we have the "First name" and "Last name" columns in our CSV files,
  but only a `:full_name` field in our database? No problem, Fields can be arbitrarily nested.

  It's just a small tweak:

  ```elixir
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

        field :first_name do
          source("last name")
        end
      end

      # ...
    end
  end
  ```

  Now our output is:

  ```elixir
  [
    #...
    {:ok, %{
      full_name: "John Smith",
      # ...
    }}
    #...
  ]
  ```

  To illustrate some more functionality, let's take a look at another example.
  We will start with a very simple CSV source file
  which will gradually become more and more complex,
  and so will our rules for parsing it.

  | Apartment/flat size (in m^2) | Price per 1 month |
  |:----------------------------:|:-----------------:|
  | 40                           | 1000              |
  | 50                           | 1100              |

  ```elixir
  defmodule PricingSchema do
    use DataQuacker.Schema

    schema :pricing do
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
  end
  ```

  The above results in:
  [
    {:ok, %{size: 40, price: 1000}},
    {:ok, %{size: 50, price: 1100}}
  ]

  This schema would work, but there are a couple of problems with it.
  First of all, it's not fun to copy&paste the function for parsing string to int
  over and over again. That's why we'll create a regular function
  and pass a reference to it in both places.

  ```elixir
  defmodule PricingSchema do
    use DataQuacker.Schema

    schema :pricing do
      field :size do
        transform(&MyModule.parse_int/1)
        # ...
      end

      field :price do
        transform(&MyModule.parse_int/1)
        # ...
      end
    end

    def parse_int(str) do
      case Integer.parse(str) do
        {int, _} -> {:ok, int}
        :error -> {:error, "Invalid value #{str} given"}
      end
    end
  end
  ```

  Note: the reference to the function must be written out in full (including the module name),
  because it will be executed in a different context.

  This is better, but still not ideal for two reasons.
  First of all, we source our data based on simple string matching. While this will still work
  if the casing in the headers changes, it will not if "Price per 1 month" changes to "Price *for* 1 month",
  or "Apartment/flat size (in m^2)" to "Apartment *or* flat size (in m^2)".
  Since most likely we do not have control over the source, these can change unexpectedly.
  Second of all, our error messages are quite vague since they do not specify the offending source row and field.

  To tackle the first one we can change our `source/1` macros to be either strings, regexes,
  lists of strings or custom functions. The details of each approach is specified
  in the docs for the `source/1` macro, but for now we will just us a list of strings.

  `source("Apartment/flat size (in m^2)")` -> `source(["apartment", "size"])`
  `source("Apartment/flat size (in m^2)")` -> `source(["price", "1"])`

  The above mean "match a header which contains apartment and size"
  and "match a header which contains apartment and 1".

  Note: The order of the headers is inconsequential.

  As for the second issue, transform can actually be given a one- or two-argument function.
  If it is given a one-argument function, the argument at execution will be the value of the field
  or row. If it is given a two-argument function, the second argument will be a `%Context{}` struct.
  Which contains the following fields: `:metadata`, `:support_data`, `:source_row`.
  Support data is an arbitrary value of any type that can be passed in at parse time.
  It can be used to, for example, validate something against a database without having to fetch the data
  for each row. More on that in the documentation of the `DataQuacker` module. For now, however, we only need `metadata` and `source_row`. The first one is a tuple
  of an atom and an atom or a tuple, where the first element is the type (`:field` or `:row`)
  and the second one is the name or index in the case of a row.
  The second one is just the index of the source row which is being processed.

  Note: the term "source row" is used here to denote a row in the input file. The term row
  is used to denote a row of output.

  We can therefore change our `parse_int/1` function into

  ```elixir
  def parse_int(str, %{metadata: metadata, source_row: source_row}) do
    case Integer.parse(str) do
      {int, _} -> {:ok, int}
      :error -> {:error, "Error processing #{elem(metadata, 0)} #{elem(metadata, 1)} in row #{source_row}; '#{str}' given"}
    end
  end
  ```

  An example error will look like this: `{:error, "Error processing field price in row 2; 'oops' given"}`

  The last case we will be dealing with here is again a "small change" to the file.

  | Apartment/flat size (in m^2) | Price per 1 month | Price per 3 months |
  |:----------------------------:|:-----------------:|--------------------|
  | 40                           | 1000              | 2800               |
  | 50                           | 1100              | 3000               |
  | 60                           |                   | 3600               |

  Now each source row contains two different prices for different lease period.
  Additionally, for the bigger apartments there may only be an option
  to rent for three months.

  We could create a schema to parse the data int rows like:
  `%{size: 40, price_1: 1000, price_3: 2800}`,
  but this is not ideal since we would have to deal with `nil` at `:price_1`,
  and we probably want separate rows in the database for each price and lease duration,
  as this allows us to easily pull out the price for a specific size and lease duration.
  A better structure therefore would look like this
  ```elixir
  [
    {:ok, %{size: 40, duration: 1, price: 1000}},
    {:ok, %{size: 40, duration: 3, price: 2800}}
    # ...
  ]
  ```

  This is where the `row/2` macro comes in. It allows us to specify any number of output rows
  for a single input row. Previously we did not use this macro at all,
  since the lack of it implies there is exactly one output row per input row.

  This is our new schema:

  ```elixir
  defmodule PricingSchema do
    use DataQuacker.Schema

    schema :pricing do
      row skip_if: (fn %{price: price} -> is_nil(price) end) do
        field :size do
          transform(&MyModule.parse_int/1)

          source(["apartment", "size"])
        end

        field :duration do
          virtual_source(1)
        end

        field :price do
          transform(&MyModule.parse_int/1)

          source(["price", "1"])
        end
      end

      row do
        field :size do
          transform(&MyModule.parse_int/1)

          source(["apartment", "size"])
        end

        field :duration do
          virtual_source(1)
        end

        field :price do
          transform(&MyModule.parse_int/1)

          source(["price", "3"])
        end
      end
    end

    def parse_int("", _), do: {:ok, nil}

    def parse_int(str, %{metadata: metadata, source_row: source_row}) do
      case Integer.parse(str) do
        {int, _} -> {:ok, int}
        :error -> {:error, "Error processing #{elem(metadata, 0)} #{elem(metadata, 1)} in row #{source_row}; '#{str}' given"}
      end
    end
  end
  ```

  There are a few new interesting things going on here.

  Firstly, as we can see, any column in the source can be inserted multiple times
  within the schema. This is particularly useful if for a single input row
  we want to have multiple output rows which share some of the fields.

  Secondly, we added a new field `:duration` which instead of being sourced from the input data
  is just a static value. We achieved it with the `virtual_source/1` macro
  which either takes a value or a function returning a value to be injected into the field.
  This is useful for us to be able to make the output structure as close to our database model as we can.

  Note: There is a special case in the `parse_int/2` function to return nil on empty input,
  because `Integer.parse/1` will return an error given an empty string.

  Lastly, we added a special option to the first output row, called `skip_if`.
  The function we provided will be evaluated for each output row representing a one-month lease price,
  and if it returns `true` the row will not appear in the actual result.

  Using our latest schema and the CSV presented above, we get this result:
  ```elixir
  [
    {:ok, %{size: 40, duration: 1, price: 1000}},
    {:ok, %{size: 40, duration: 3, price: 2800}},
    {:ok, %{size: 50, duration: 1, price: 1100}},
    {:ok, %{size: 50, duration: 3, price: 3000}},
    {:ok, %{size: 50, duration: 1, price: 3600}}
  ]
  ```
  """

  alias DataQuacker.Schema.State

  alias DataQuacker.SchemaError

  import DataQuacker.Schema.FunWrapper

  @doc false
  defmacro __using__(_opts) do
    quote do
      import unquote(__MODULE__)

      @state State.new()
    end
  end

  @doc ~S"""
  Defines a schema and a `schema_structure/1` function
  which takes the schema name as the argument
  and returns the schema in a form that can be passed to a parser.

  The result structure is a map with the following types:
  ```elixir
  %{
    __name__: atom(),
    rows: list(),
    matchers: list()
  }
  ```

  The macro takes in a name and a block with which the rows, fields, etc. can be defined.
  The block must contain at least one row. Note, however, that if no row is explicitly specified,
  but at least one field is, the schema is assumed to have exactly one row which contains all of the fields.

  Note: if one or many fields are present directly inside the schema, the row macro cannot be used explicitly.
  The same is true the other way around - if at least one row is specified explicitly,
  fields can only appear inside rows, not directly in the schema.

  Unlike `row/2` and `field/3`, the `schema/2` macro cannot have validators or parsers.
  If there is only one row, but it needs to define validators or parses,
  the schema must define this row explicitly.
  """
  defmacro schema(name, do: block) do
    quote do
      if not Enum.empty?(@state.cursor) do
        raise SchemaError, """

        Invalid schema position.
        Schema can only appear as a top-level module macro
        (cannot be nested in other schemas).
        """
      end

      @state State.new()
      @state State.register(@state, :schema, {unquote(name), %{}})

      unquote(block)

      if Enum.empty?(@state.rows) do
        raise SchemaError, """

        Invalid schema usage.
        Schema must have at least
        one row or one field.
        """
      end

      if State.flagged?(@state, :has_loose_fields?) do
        @state State.update(@state, :row, %{fields: @state.fields})

        @state State.cursor_exit(@state)
      end

      @state State.cursor_exit(@state)

      @state State.update(@state, :schema, %{
               matchers: @state.matchers,
               rows: @state.rows
             })

      def schema_structure(unquote(name)) do
        @state.schema
      end
    end
  end

  @doc ~S"""
  Defines an output row.
  Can only be used directly inside a schema, and only if the schema has no fields
  directly inside it.

  This macro takes in a keyword list of options, and a block within which the fields,
  validators and parsers can be specified.

  ## Options
    * `:skip_if` - a function of arity 1 or 2, which returns `true` or `false` given the value of the row and optionally the context; `true` means the row should be skipped from the output, `false` is a "noop"
  """
  defmacro row(opts \\ [], do: block) do
    quote do
      if State.flagged?(@state, :has_loose_fields?) do
        raise SchemaError, """

        Invalid row usage.
        Rows cannot appear in a schema
        if the schema has loose fields
        (fields appearing outside of any row).
        """
      end

      if not State.cursor_at?(@state, :schema) do
        raise SchemaError, """

        Invalid row position.
        Rows can only appear directly
        inside a schema.
        """
      end

      @state State.clear_fields(@state)
      @state State.register(
               @state,
               :row,
               {length(@state.rows), %{skip_if: skip_if_opt(unquote(opts))}}
             )

      unquote(block)

      @state State.update(@state, :row, %{fields: @state.fields})

      if @state.fields == %{} do
        raise SchemaError, """

        Invalid row usage.
        Rows must have at least one subfield.
        """
      end

      @state State.cursor_exit(@state)
    end
  end

  @doc ~S"""
  Defines an output field.
  Can be used inside a schema, a row or another field.
  Can only be used directly inside a schema if the schema has no explicitly defined rows.
  Can only be used inside another field if that field has no source.

  This macro takes in a name, a keyword list of options, and a block within which the subfields or source,
  and validators and parsers can be specified.
  Can either specify exactly one source (virtual or regular) or subfields.

  ## Options
    * `:skip_if` - a function of arity 1 or 2, which returns `true` or `false` given the value of the field and optionally the context; `true` means the field should be skipped from the output, `false` is a "noop"
  """
  defmacro field(name, opts \\ [], do: block) do
    quote do
      if State.cursor_at?(@state, nil) do
        raise SchemaError, """

        Invalid field position.
        Fields can only appear inside a schema,
        rows or other fields.
        """
      end

      if State.cursor_at?(@state, :schema) and not Enum.empty?(@state.rows) do
        raise SchemaError, """

        Invalid field usage.
        Fields cannot appear directly inside a schema
        if the schema explicitly declares rows.
        """
      end

      if State.cursor_at?(@state, :schema) do
        @state State.flag(@state, :has_loose_fields?, true)
        @state State.register(@state, :row, {length(@state.rows), %{}})
      end

      if State.cursor_at?(@state, :field) and State.get(@state, :field).__type__ == :sourced do
        raise SchemaError, """

        Invalid field usage.
        A field can either have subfields or a source,
        but not both.
        """
      end

      if State.cursor_at?(@state, :field) do
        @state State.update(@state, :field, %{__type__: :wrapper})
      end

      @state State.register(
               @state,
               :field,
               {unquote(name), %{skip_if: skip_if_opt(unquote(opts))}}
             )

      unquote(block)

      if is_nil(State.get(@state, :field).__type__) do
        raise SchemaError, """

        Invalid field usage.
        Fields must either have a source
        or at least one subfield.
        """
      end

      @state State.cursor_exit(@state)
    end
  end

  @doc ~S"""
  Defines a source mapping from the input.
  Can only be used inside a field, and only if that field does not define any subfields
  or any other source.

  This macro takes in either a "needle" which can be string, a regex, a list of strings,
  or a function of arity 1 or 2.

  ## Needle
    * when is a string - the downcased header name for a particular column must contain the downcased string given as the needle for the column to match
    * when is a regex - the header name for a particular column must match the needle for the column to match
    * when is a list of strings - the downcase header name for a particular column must contain all of the downcased elements given as the needle for the column to match
    * when is a function - given the header name for a particular column, and optionally the context, must return `true` for the column to match; the function must always return `true` or `false`
  """
  defmacro source(needle) do
    {unquoted_needle, _} = Code.eval_quoted(needle)

    case unquoted_needle do
      string when is_binary(string) ->
        quote do
          source(fn column_name ->
            String.contains?(String.downcase(column_name), unquote(String.downcase(needle)))
          end)
        end

      list when is_list(list) ->
        quote do
          source(fn column_name ->
            column_name = String.downcase(column_name)

            unquote(Enum.map(needle, &String.downcase(&1)))
            |> Enum.all?(&String.contains?(column_name, &1))
          end)
        end

      %Regex{} ->
        quote do
          source(fn column_name ->
            Regex.match?(unquote(needle), column_name)
          end)
        end

      fun when is_function(fun) ->
        quote do
          if not State.cursor_at?(@state, :field) do
            raise SchemaError, """

            Invalid source position.
            Sources can only appear inside fields.
            """
          end

          if State.get(@state, :field).__type__ == :sourced do
            raise SchemaError, """

            Invalid source usage.
            Only one source per field is allowed.
            """
          end

          if State.get(@state, :field).__type__ == :wrapper do
            raise SchemaError, """

            Invalid source usage.
            A field can either have subfields or a source,
            but not both.
            """
          end

          @state State.register(@state, :matcher, wrap_fun(unquote(needle), 1..2))
          @state State.update(@state, :field, %{__type__: :sourced, source: State.target(@state)})
        end

      _ ->
        quote do
          raise SchemaError, """

          Invalid column source type.
          Must be a string, a regex expression or a function
          which can be used to match a column name.
          """
        end
    end
  end

  @doc ~S"""
  Defines a value to be injected to a particular field.
  Can only be used inside a field, and only if that field does not define any subfields
  or any other source.

  This macro takes in either a literal value, or a function of arity 0 or 1.

  ## Value
    * when is a function - optionally given the context, can return any value to be injected inside the field
    * else - the value is injected inside the field "as is"
  """
  defmacro virtual_source(value) do
    {unquoted_value, _} = Code.eval_quoted(value)

    case unquoted_value do
      fun when is_function(fun) ->
        quote do
          if not State.cursor_at?(@state, :field) do
            raise SchemaError, """

            Invalid source position.
            Sources can only appear inside fields.
            """
          end

          if State.get(@state, :field).__type__ == :sourced do
            raise SchemaError, """

            Invalid source usage.
            Only one source per field is allowed.
            """
          end

          if State.get(@state, :field).__type__ == :wrapper do
            raise SchemaError, """

            Invalid source usage.
            A field can either have subfields or a source,
            but not both.
            """
          end

          @state State.update(@state, :field, %{
                   __type__: :sourced,
                   source: wrap_fun(unquote(value), 0..1)
                 })
        end

      _ ->
        quote do
          virtual_source(fn -> unquote(value) end)
        end
    end
  end

  defmacro validate(fun) do
    quote do
      validator = wrap_fun(unquote(fun), 1..2)

      cond do
        State.cursor_at?(@state, :row) ->
          validators = @state |> State.get(:row) |> Map.get(:validators)

          @state State.update(@state, :row, %{validators: [validator | validators]})

        State.cursor_at?(@state, :field) ->
          validators = @state |> State.get(:field) |> Map.get(:validators)

          @state State.update(@state, :field, %{validators: [validator | validators]})

        true ->
          raise SchemaError, """

          Incorrect validator position.
          Validators can only appear
          inside rows or fields.
          """
      end
    end
  end

  defmacro transform(fun) do
    quote do
      transformer = wrap_fun(unquote(fun), 1..2)

      cond do
        State.cursor_at?(@state, :row) ->
          transformers = @state |> State.get(:row) |> Map.get(:transformers)

          @state State.update(@state, :row, %{transformers: [transformer | transformers]})

        State.cursor_at?(@state, :field) ->
          transformers = @state |> State.get(:field) |> Map.get(:transformers)

          @state State.update(@state, :field, %{transformers: [transformer | transformers]})

        true ->
          raise SchemaError, """

          Incorrect transformer position.
          Transformers can only appear
          inside rows or fields.
          """
      end
    end
  end

  @doc false
  defmacro skip_if_opt(opts) do
    {unquoted_opts, _} = Code.eval_quoted(opts)

    case Keyword.fetch(unquoted_opts, :skip_if) do
      {:ok, fun} when is_function(fun) ->
        quote do
          wrap_fun(unquote(Keyword.get(opts, :skip_if)), 1..2)
        end

      :error ->
        quote do
          nil
        end

      _ ->
        quote do
          raise SchemaError, """

          Invalid skip_if type
          must be a function
          with arity 1 or 2.
          """
        end
    end
  end
end
