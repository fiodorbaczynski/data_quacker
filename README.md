# DataQuacker

DataQuacker is a library which aims at helping validating, transforming and parsing non-sandboxed data, like CSV files.

It features a simple DSL similar to that of Ecto, which allows the user to declaratively describe the rules for mapping columns in the source into a desired structure. It also makes it easy to specify rules for validating, transforming and skipping specific fields and rows.

The documentation along with usage examples can be found at [hexdocs.pm](https://hexdocs.pm/data_quacker/DataQuacker.html)

To see the next steps for this library take a look at: [todo.md](./docs/todo.md)

## Installation

To install the library, add it to your `mix.exs` deps.

```elixir
def deps do
  [
    {:data_quacker, "~> 0.1.0"}
  ]
end
```

## Contribution

Any contribution is greatly appreciated. If you find anything working incorrectly or missing in this library or its documentation, please open an issue or a pull request.

Issues inquiring about usage and best practices are also welcome.

## Testimonials

"..." ~ the rubber duck on my desk
