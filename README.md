# DataQuacker

DataQuacker aims at making it easier to validate, transform and parse CSV files.

It features a simple DSL similar to those of Ecto's and Absinthe's schemas, which allows the user to declaratively describe the rules for mapping columns in a CSV file into a desired structure. It also makes it easy to specify rules for validating, transforming and skipping specific fields and rows.

This library is still a work in progress. To see the list of "todo tasks" go to [todo.md](./docs/todo.md)

## Installation

To install the library, add it to your `mix.deps`.

```elixir
def deps do
  [
    {:data_quacker, "https://github.com/fiodorbaczynski/data_quacker.git"}
  ]
end
```

## Contribution

Any contribution, including reporting issues, is greatly appreciated. You may contribute anything you feel is needed, but the tasks listed in [todo.md](./docs/todo.md) are the most important for now for DataQuacker to be "1.0-ready".

## Testimonials

"..." ~ the rubber duck on my desk
