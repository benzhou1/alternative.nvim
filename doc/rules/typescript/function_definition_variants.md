# typescript.function_definition_variants

## Source Code

<details>
<summary><strong>Show</strong></summary>

```lua
local utils = require("alternative.utils")

-- Extend the javascript rules and change the replacement function
return {
  {
    input = {
      type = "query",
      pattern = [[
        (function_declaration
          name: (identifier) @name
          parameters: (_) @parameters
          body: (_) @body
        ) @__input__
      ]],
      container = "function_declaration",
    },
    preview = true,
    trigger = function(input)
      -- The cursor should be at the function text
      local valid_range = { input.range[1], input.range[2], input.range[1], input.range[2] + 7 }
      return utils.cursor_in_range(valid_range)
    end,
    replacement = function(ctx)
      local function_node = ctx.query_captures["__input__"][1]
      local return_type = function_node:field("return_type")[1]

      if return_type then
        local return_type_text = vim.treesitter.get_node_text(return_type, 0)
        return {
          string.format("const @name = function @parameters%s @body", return_type_text),
          string.format("const @name = @parameters%s => @body", return_type_text),
        }
      else
        return {
          "const @name = function @parameters @body",
          "const @name = @parameters => @body",
        }
      end
    end,
    filetype = { "typescript", "typescriptreact" },
    description = "Convert function declaration to function expression or arrow function",
    note = "Only triggers when the cursor is in the `function` text",
    example = {
      input = utils.format_indentation([[
        func|tion foo(a: number, b: number): boolean {
          return a == b
        }
      ]]),
      output = utils.format_indentation([[
        const foo = function (a: number, b: number): boolean {
          return a == b
        }

        // Or

        const foo = (a: number, b: number): boolean => {
          return a == b
        }
      ]]),
    },
  },
  {
    input = {
      type = "query",
      pattern = [[
        (lexical_declaration
          (variable_declarator
            name: (identifier) @name
            value: (function_expression
              parameters: (_) @parameters
              body: (_) @body
            ) @function
          )
        ) @__input__
      ]],
      container = "lexical_declaration",
    },
    preview = true,
    trigger = function(input)
      local function_node = input.ts_captures["function"]
      local range_1, range_2 = function_node[1]:range()
      -- The cursor should be at the function text
      local valid_range = { range_1, range_2, range_1, range_2 + 7 }
      return utils.cursor_in_range(valid_range)
    end,
    replacement = function(ctx)
      local function_node = ctx.query_captures["function"][1]
      local return_type = function_node:field("return_type")[1]

      if return_type then
        local return_type_text = vim.treesitter.get_node_text(return_type, 0)
        return {
          string.format("function @name@parameters%s @body", return_type_text),
          string.format("const @name = @parameters%s => @body", return_type_text),
        }
      else
        return {
          "function @name@parameters @body",
          "const @name = @parameters => @body",
        }
      end
    end,
    filetype = { "typescript", "typescriptreact" },
    description = "Convert function expression to function declaration or arrow function",
    note = "Only triggers when the cursor is in the `function` text",
    example = {
      input = utils.format_indentation([[
        const foo = func|tion (a: number, b: number): boolean {
          return a == b
        }
      ]]),
      output = utils.format_indentation([[
        function foo(a, b) {
          return a == b
        }

        // Or

        const foo = (a: number, b: number): boolean => {
          return a == b
        }
      ]]),
    },
  },
  {
    input = {
      type = "query",
      pattern = [[
        (lexical_declaration
          (variable_declarator
            name: (identifier) @name
            value: (arrow_function
              parameters: (_) @parameters
              body: (_) @body
            ) @function
          )
        ) @__input__
      ]],
      container = "lexical_declaration",
    },
    preview = true,
    trigger = function(input)
      -- The cursor should be at the the first line
      local valid_range = { input.range[1], input.range[2], input.range[1] + 1, 0 }
      return utils.cursor_in_range(valid_range)
    end,
    replacement = function(ctx)
      local function_node = ctx.query_captures["function"][1]
      local return_type = function_node:field("return_type")[1]

      if return_type then
        local return_type_text = vim.treesitter.get_node_text(return_type, 0)
        return {
          string.format("function @name@parameters%s @body", return_type_text),
          string.format("const @name = function @parameters%s @body", return_type_text),
        }
      else
        return {
          "function @name@parameters @body",
          "const @name = function @parameters @body",
        }
      end
    end,
    filetype = { "typescript", "typescriptreact" },
    description = "Convert arrow function to function declaration or function expression",
    note = "Only triggers when the cursor is in the first line the the function definition",
    example = {
      input = utils.format_indentation([[
        con|st foo = (a: number, b: number): boolean => {
          return a == b
        }
      ]]),
      output = utils.format_indentation([[
        function foo(a: number, b: number): boolean {
          return a == b
        }

        // Or

        const foo = function (a: number, b: number): boolean {
          return a == b
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

### Convert function declaration to function expression or arrow function

> [!NOTE]
> Only triggers when the cursor is in the `function` text

- Input:

```typescript
func|tion foo(a: number, b: number): boolean {
  return a == b
}
```

- Output:

```typescript
const foo = function (a: number, b: number): boolean {
  return a == b
}

// Or

const foo = (a: number, b: number): boolean => {
  return a == b
}
```

### Convert function expression to function declaration or arrow function

> [!NOTE]
> Only triggers when the cursor is in the `function` text

- Input:

```typescript
const foo = func|tion (a: number, b: number): boolean {
  return a == b
}
```

- Output:

```typescript
function foo(a, b) {
  return a == b
}

// Or

const foo = (a: number, b: number): boolean => {
  return a == b
}
```

### Convert arrow function to function declaration or function expression

> [!NOTE]
> Only triggers when the cursor is in the first line the the function definition

- Input:

```typescript
con|st foo = (a: number, b: number): boolean => {
  return a == b
}
```

- Output:

```typescript
function foo(a: number, b: number): boolean {
  return a == b
}

// Or

const foo = function (a: number, b: number): boolean {
  return a == b
}
```