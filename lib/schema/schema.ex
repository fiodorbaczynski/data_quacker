defmodule TrivialCsv.Schema do
  alias TrivialCsv.Schema.State

  alias TrivialCsv.SchemaError

  import TrivialCsv.Schema.FunWrapper

  defmacro __using__(_opts) do
    quote do
      import unquote(__MODULE__)

      @state State.new()
    end
  end

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

  defmacro virtual_source(data) do
    {unquoted_data, _} = Code.eval_quoted(data)

    case unquoted_data do
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
                   source: wrap_fun(unquote(data), 0..1)
                 })
        end

      _ ->
        quote do
          virtual_source(fn -> unquote(data) end)
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
