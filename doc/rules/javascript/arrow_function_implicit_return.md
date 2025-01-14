# javascript.arrow_function_implicit_return

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
        (arrow_function
          parameters: (_) @parameters
          body: (_) @body
          (#not-type? @body "statement_block")
        ) @__input__
      ]],
      container = "arrow_function",
      lookahead = true,
    },
    trigger = function(ctx)
      return utils.get_current_word(ctx) == "=>"
    end,
    replacement = utils.format_indentation([[
      @parameters => {
        return @body
      }
    ]]),
    filetype = { "javascript", "typescript", "javascriptreact", "typescriptreact" },
    description = "Convert arrow function with implicit return to explicit return",
    note = "Only triggers when the cursor is on the arrow (=>) text",
    example = {
      input = utils.format_indentation([[
        const add = (a, b) =|> a + b
      ]]),
      output = utils.format_indentation([[
        const add = (a, b) => {
          return a + b
        }
      ]]),
    },
  },
  {
    input = {
      type = "query",
      pattern = [[
        (arrow_function
          parameters: (_) @parameters
          body:
            (statement_block
              .
              (return_statement
                (_) @return
              )
            )
        ) @__input__
      ]],
      container = "arrow_function",
      lookahead = true,
    },
    trigger = function(ctx)
      return utils.get_current_word(ctx) == "=>"
    end,
    replacement = utils.format_indentation([[
      @parameters => @return
    ]]),
    filetype = { "javascript", "typescript", "javascriptreact", "typescriptreact" },
    description = "Convert arrow function with explicit return to implicit return",
    note = "Only triggers when the cursor is on the arrow (=>) text",
    example = {
      input = utils.format_indentation([[
        const add = (a, b) => {
          return a + b
        }
      ]]),
      output = utils.format_indentation([[
        const add = (a, b) =|> a + b
      ]]),
    },
  },
}
```

</details>

## Examples

> [!NOTE]
> `|` denotes the cursor position.

### Convert arrow function with implicit return to explicit return

> [!NOTE]
> Only triggers when the cursor is on the arrow (=>) text

- Input:

```javascript
const add = (a, b) =|> a + b
```

- Output:

```javascript
const add = (a, b) => {
  return a + b
}
```

### Convert arrow function with explicit return to implicit return

> [!NOTE]
> Only triggers when the cursor is on the arrow (=>) text

- Input:

```javascript
const add = (a, b) => {
  return a + b
}
```

- Output:

```javascript
const add = (a, b) =|> a + b
```