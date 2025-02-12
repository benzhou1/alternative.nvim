# elixir.if_expression_variants

## Source Code

<details>
<summary><strong>Show</strong></summary>

```lua
local utils = require("alternative.utils")

return {
  {
    input = {
      type = "query",
      -- Match if expressions that have single expression body
      pattern = [[
        (
          (call
            target: (identifier) @identifier
            (arguments) @condition
            (do_block
              .
              (_) @body
              .
            )
          ) @__input__
          (#eq? @identifier "if")
        )
      ]],
      container = "call",
    },
    trigger = function(ctx)
      return utils.get_current_word(ctx) == "if"
    end,
    replacement = "if @condition, do: @body",
    filetype = "elixir",
    description = "if expression: long form to short form",
    example = {
      input = utils.format_indentation([[
        if foo do
          bar
        end
      ]]),
      output = "if foo, do: bar",
    },
  },
  {
    input = {
      type = "query",
      -- Match if/else expressions that have single expression body
      pattern = [[
        (
          (call
            target: (identifier) @identifier
            (arguments) @condition
            (do_block
              .
              (_) @if_body
              .
              (else_block
                .
                (_) @else_body
                .
              )
              .
            )
          ) @__input__
          (#eq? @identifier "if")
        )
      ]],
      container = "call",
    },
    trigger = function(ctx)
      return utils.get_current_word(ctx) == "if"
    end,
    replacement = "if @condition, do: @if_body, else: @else_body",
    filetype = "elixir",
    description = "if/else expression: long form to short form",
    example = {
      input = utils.format_indentation([[
        if foo do
          bar
        else
          baz
        end
      ]]),
      output = "if foo, do: bar, else: baz",
    },
  },
  {
    input = {
      type = "query",
      -- Match if expressions that have do keyword
      pattern = [[
        (
          (call
            target: (identifier) @identifier
            (arguments
              .
              (_) @condition
              (keywords
                .
                (pair
                  key: (keyword) @key
                  value: (_) @do_body
                )
                .
              )
              .
            )
          ) @__input__
          (#eq? @identifier "if")
          (#match? @key "^do")
        )
      ]],
      container = "call",
    },
    trigger = function(ctx)
      return utils.get_current_word(ctx) == "if"
    end,
    replacement = utils.format_indentation([[
      if @condition do
        @do_body
      end
    ]]),
    filetype = "elixir",
    description = "if expression: short form to long form",
    example = {
      input = "if foo, do: bar",
      output = utils.format_indentation([[
        if foo do
          bar
        end
      ]]),
    },
  },
  {
    input = {
      type = "query",
      -- Match if/else expressions that have do keyword
      pattern = [[
        (
          (call
            target: (identifier) @identifier
            (arguments
              .
              (_) @condition
              (keywords
                .
                (pair
                  key: (keyword) @key1
                  value: (_) @do_body
                )
                .
                (pair
                  key: (keyword) @key2
                  value: (_) @else_body
                )
                .
              )
              .
            )
          ) @__input__
          (#eq? @identifier "if")
          (#match? @key1 "^do")
          (#match? @key2 "^else")
        )
      ]],
      container = "call",
    },
    trigger = function(ctx)
      return utils.get_current_word(ctx) == "if"
    end,
    replacement = utils.format_indentation([[
      if @condition do
        @do_body
      else
        @else_body
      end
    ]]),
    filetype = "elixir",
    description = "if/else expression: short form to long form",
    example = {
      input = "if foo, do: bar, else: baz",
      output = utils.format_indentation([[
        if foo do
          bar
        else
          baz
        end
      ]]),
    },
  },
}
```

</details>

## Examples

> [!NOTE]
> `|` denotes the cursor position.

### if expression: long form to short form



- Input:

```elixir
if foo do
  bar
end
```

- Output:

```elixir
if foo, do: bar
```

### if/else expression: long form to short form



- Input:

```elixir
if foo do
  bar
else
  baz
end
```

- Output:

```elixir
if foo, do: bar, else: baz
```

### if expression: short form to long form



- Input:

```elixir
if foo, do: bar
```

- Output:

```elixir
if foo do
  bar
end
```

### if/else expression: short form to long form



- Input:

```elixir
if foo, do: bar, else: baz
```

- Output:

```elixir
if foo do
  bar
else
  baz
end
```