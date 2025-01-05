# javascript.ternary_to_if_else

## Source Code

<details>
<summary><strong>Show</strong></summary>

```lua
local utils = require("alternative.utils")

return {
  {
    input = {
      type = "query",
      pattern = [[
        (lexical_declaration
          (variable_declarator
            name: (_) @variable
            value:
              (ternary_expression
                condition: (_) @condition
                consequence: (_) @consequence
                alternative: (_) @alternative
              )
          )
        ) @__input__
      ]],
      container = "lexical_declaration",
    },
    replacement = utils.format_indentation([[
      const @variable
      if (@condition) {
        @variable = @consequence
      } else {
        @variable = @alternative
      }
    ]]),
    preview = true,
    filetype = { "javascript", "typescript", "javascriptreact", "typescriptreact" },
    description = "Convert ternary expression in declaration",
    example = {
      input = utils.format_indentation([[
        const fo|o = a ? b : c
      ]]),
      output = utils.format_indentation([[
        const foo
        if (a) {
          foo = b
        } else {
          foo = c
        }
      ]]),
    },
  },
  {
    input = {
      type = "query",
      pattern = [[
        (assignment_expression
          left: (_) @variable
          right:
            (ternary_expression
              condition: (_) @condition
              consequence: (_) @consequence
              alternative: (_) @alternative
            )
        ) @__input__
      ]],
      container = "assignment_expression",
    },
    replacement = utils.format_indentation([[
      if (@condition) {
        @variable = @consequence
      } else {
        @variable = @alternative
      }
    ]]),
    preview = true,
    filetype = { "javascript", "typescript", "javascriptreact", "typescriptreact" },
    description = "Convert ternary expression in assignment",
    example = {
      input = utils.format_indentation([[
        fo|o = a ? b : c
      ]]),
      output = utils.format_indentation([[
        if (a) {
          foo = b
        } else {
          foo = c
        }
      ]]),
    },
  },
  {
    input = {
      type = "query",
      pattern = [[
        (return_statement
          (ternary_expression
            condition: (_) @condition
            consequence: (_) @consequence
            alternative: (_) @alternative
          )
        ) @__input__
      ]],
      container = "return_statement",
    },
    replacement = utils.format_indentation([[
      if (@condition) {
        return @consequence
      } else {
        return @alternative
      }
    ]]),
    preview = true,
    filetype = { "javascript", "typescript", "javascriptreact", "typescriptreact" },
    description = "Convert ternary expression in return statement",
    example = {
      input = utils.format_indentation([[
        return a ? b : c
      ]]),
      output = utils.format_indentation([[
        if (a) {
          return b
        } else {
          return c
        }
      ]]),
    },
  },
}
```

</details>

## Examples

> [!NOTE]
> `|` denotes the cursor position.

### Convert ternary expression in declaration

- Input:

```lua
const fo|o = a ? b : c
```

- Output:

```lua
const foo
if (a) {
  foo = b
} else {
  foo = c
}
```

### Convert ternary expression in assignment

- Input:

```lua
fo|o = a ? b : c
```

- Output:

```lua
if (a) {
  foo = b
} else {
  foo = c
}
```

### Convert ternary expression in return statement

- Input:

```lua
return a ? b : c
```

- Output:

```lua
if (a) {
  return b
} else {
  return c
}
```