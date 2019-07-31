defmodule TrivialCsv.Schema.StateTest do
  use ExUnit.Case, async: true

  alias TrivialCsv.Schema.State

  describe "new/0" do
    test "should return an empty State struct" do
      assert State.new() == %State{
               cursor: [],
               flags: %{},
               schema: %{},
               matchers: [],
               rows: [],
               fields: %{}
             }
    end
  end

  describe "clear_fields/1" do
    setup do
      {:ok, state: %State{fields: %{a: 1, b: 2, c: 3}}}
    end

    test "should clear the fields", %{state: state} do
      state = State.clear_fields(state)

      assert state.fields == %{}
    end
  end

  describe "flag/3" do
    setup do
      {:ok, state: %State{flags: %{a: true, b: false}}}
    end

    test "should put a flag with a value", %{state: state} do
      state = State.flag(state, :c, true)

      assert state.flags.c == true
    end

    test "should replace the value of an already existing flag", %{state: state} do
      state = State.flag(state, :b, true)

      assert state.flags.b == true
    end
  end

  describe "flagged?/2" do
    setup do
      {:ok, state: %State{flags: %{a: true, b: false}}}
    end

    test "should get the value of a flag", %{state: state} do
      assert State.flagged?(state, :a) == true
      assert State.flagged?(state, :b) == false
    end

    test "should return false if a flag does not exist", %{state: state} do
      assert State.flagged?(state, :c) == false
    end
  end

  describe "cursor_at/2" do
    setup do
      {:ok,
       empty_cursor_state: %State{cursor: []},
       state: %State{cursor: [{:field, :sample_field}, {:row, 0}]}}
    end

    test "given a state with an empty cursor and compare the needle with nil", %{
      empty_cursor_state: empty_cursor_state
    } do
      assert State.cursor_at?(empty_cursor_state, nil) == true
      assert State.cursor_at?(empty_cursor_state, 123) == false
      assert State.cursor_at?(empty_cursor_state, "abc") == false
    end

    test "given a cursor should compare the latest pointer's type to the needle", %{
      state: state
    } do
      assert State.cursor_at?(state, :field) == true
      assert State.cursor_at?(state, :row) == false
    end
  end

  describe "target/1" do
    setup do
      {:ok, state: %State{cursor: [{:field, :abc}, {:row, 0}, {:schema, :def}]}}
    end

    test "should return a list of values at subsequent cursor entries (without the types)", %{
      state: state
    } do
      assert State.target(state) == [:abc, 0, :def]
    end
  end

  describe "cursor_exit/1" do
    setup do
      {:ok, state: %State{cursor: [{:field, :abc}, {:row, 0}, {:schema, :def}]}}
    end

    test "should drop the cursor's head", %{state: state} do
      assert State.cursor_exit(state) == %State{cursor: [{:row, 0}, {:schema, :def}]}
    end

    test "given the exit level should the cursor's first n elements", %{state: state} do
      assert State.cursor_exit(state, 2) == %State{cursor: [{:schema, :def}]}
    end
  end

  describe "register/3" do
    setup do
      blank_state = %State{}
      state_with_schema = State.register(blank_state, :schema, {:abc, %{}})
      state_with_row = State.register(state_with_schema, :row, {0, %{}})
      state_with_field = State.register(state_with_row, :field, {:def, %{}})

      {:ok,
       blank_state: blank_state,
       state_with_schema: state_with_schema,
       state_with_row: state_with_row,
       state_with_field: state_with_field}
    end

    test "given a schema should add the schema merged with the default to the state", %{
      blank_state: state
    } do
      assert %State{cursor: [{:schema, :abc}], schema: %{__name__: :abc, matchers: [], rows: []}} =
               State.register(state, :schema, {:abc, %{}})
    end

    test "given a row should add the row merged with the default to the state", %{
      state_with_schema: state
    } do
      assert %State{
               cursor: [{:row, 0}, {:schema, :abc}],
               rows: [%{__index__: 0, fields: %{}, parsers: [], skip_if: nil, validators: []}]
             } = State.register(state, :row, {0, %{}})
    end

    test "given a field should add the field merged with the default to the state", %{
      state_with_row: state
    } do
      assert %State{
               cursor: [{:field, :def}, {:row, 0}, {:schema, :abc}],
               fields: %{
                 def: %{
                   __name__: :def,
                   __type__: nil,
                   parsers: [],
                   skip_if: nil,
                   source: nil,
                   subfields: %{},
                   validators: []
                 }
               }
             } = State.register(state, :field, {:def, %{}})
    end

    test "given a field when the cursor is already at a field should add the field merged with the default to the state as a subfield",
         %{
           state_with_field: state
         } do
      assert %State{
               cursor: [{:field, :ghi}, {:field, :def}, {:row, 0}, {:schema, :abc}],
               fields: %{
                 def: %{
                   subfields: %{
                     ghi: %{
                       __name__: :ghi,
                       __type__: nil,
                       parsers: [],
                       skip_if: nil,
                       source: nil,
                       subfields: %{},
                       validators: []
                     }
                   }
                 }
               }
             } = State.register(state, :field, {:ghi, %{}})
    end

    test "given a matcher should add the matcher merged with the default to the state with the current cursor as the target",
         %{state_with_field: state} do
      assert %State{matchers: [%{rule: "some rule", target: target}]} =
               State.register(state, :matcher, "some rule")

      assert target == State.target(state)
    end
  end

  describe "update/3" do
    setup do
      state_with_schema = State.register(%State{}, :schema, {:abc, %{}})
      state_with_row = State.register(state_with_schema, :row, {0, %{}})
      state_with_field = State.register(state_with_row, :field, {:def, %{}})
      state_with_nested_field = State.register(state_with_field, :field, {:ghi, %{}})

      {:ok,
       state_with_schema: state_with_schema,
       state_with_row: state_with_row,
       state_with_field: state_with_field,
       state_with_nested_field: state_with_nested_field}
    end

    test "given a schema should update the existing schema", %{
      state_with_schema: state
    } do
      assert %State{schema: %{some_field: 123}} = State.update(state, :schema, %{some_field: 123})
    end

    test "given a row should update the row that the cursor is pointing at", %{
      state_with_row: state
    } do
      assert %State{rows: [%{some_field: 123}]} = State.update(state, :row, %{some_field: 123})
    end

    test "given a field should update the field the cursor is pointing at", %{
      state_with_field: state
    } do
      assert %State{fields: %{def: %{some_field: 123}}} =
               State.update(state, :field, %{some_field: 123})
    end

    test "given a field should update the field the cursor is pointing at (nested)",
         %{
           state_with_nested_field: state
         } do
      assert %State{fields: %{def: %{subfields: %{ghi: %{some_field: 123}}}}} =
               State.update(state, :field, %{some_field: 123})
    end
  end
end
