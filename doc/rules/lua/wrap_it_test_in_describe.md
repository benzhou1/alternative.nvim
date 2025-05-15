# lua.wrap_it_test_in_describe

## Source Code

<details>
<summary><strong>Show</strong></summary>

```lua
local utils = require("alternative.utils")

return {
  input = {
    type = "query",
    pattern = [[
      (
        (function_call
          name: (identifier) @name
          arguments:
            (arguments
              (string
                content: (string_content) @description
              )
              (function_definition) @body
            ) @args
        ) @__input__
        (#eq? @name "it")
      )
    ]],
    container = "function_call",
  },
  trigger = function()
    local filename = vim.fn.expand("%:t")
    return filename:match("test.lua") or filename:match("spec.lua")
  end,
  replacement = utils.format_indentation([[
    describe("@description", function()
      it("", @body)
    end)
  ]]),
  preview = true,
  filetype = "lua",
  description = "Wrap the Lua it function in describe function. Only applies for test files",
  example = {
    input = utils.format_indentation([[
      it("should return true", function()
        local foo = a and b or c
      end)
    ]]),
    output = utils.format_indentation([[
      describe("should return true", function()
        it("", function()
          local foo = a and b or c
        end)
      end)
    ]]),
  },
}
```

</details>

## Examples

> [!NOTE]
> `|` denotes the cursor position.

### Wrap the Lua it function in describe function. Only applies for test files



- Input:

```lua
it("should return true", function()
  local foo = a and b or c
end)
```

- Output:

```lua
describe("should return true", function()
  it("", function()
    local foo = a and b or c
  end)
end)
```
