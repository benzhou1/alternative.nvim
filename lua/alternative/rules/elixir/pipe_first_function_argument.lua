local _utils = require("custom.utils")
local utils = require("alternative.utils")
local ignore_built_in_functions = [[(#not-any-of? @function_name "if" "case" "cond" "with" "def" "defp" "defmacro")]]

return {
  {
    input = {
      type = "query",
      -- Single argument function call
      pattern = string.format(
        [[
          (
            (call
              target: (_) @function_name
              (arguments
                .
                (_) @argument
                .
              )
            ) @__input__
            %s
          )
        ]],
        ignore_built_in_functions
      ),
      container = "call",
    },
    -- Only trigger when the cursor is in the function name
    trigger = function(ctx)
      local function_name = ctx.ts_captures.function_name[1]
      local srow, scol, erow, ecol = vim.treesitter.get_node_range(function_name)
      return utils.cursor_in_range({ srow, scol, erow, ecol })
    end,
    replacement = "@argument |> @function_name()",
    filetype = "elixir",
    description = "Pipe the first argument. Only triggers when the cursor is in the function name",
    example = {
      input = "foo(bar)",
      output = "bar |> foo()",
    },
  },
  {
    input = {
      type = "query",
      -- Multiple arguments function call
      pattern = string.format(
        [[
          (
            (call
              target: (_) @function_name
              (arguments
                .
                (_) @first_argument
                .
                (_) @second_argument
              ) @arguments
            ) @__input__
            %s
          )
        ]],
        ignore_built_in_functions
      ),
      container = "call",
    },
    -- Only trigger when the cursor is in the function name
    trigger = function(ctx)
      local function_name = ctx.ts_captures.function_name[1]
      local srow, scol, erow, ecol = vim.treesitter.get_node_range(function_name)
      return utils.cursor_in_range({ srow, scol, erow, ecol })
    end,
    replacement = function(ctx)
      local _, _, args_erow, args_ecol = vim.treesitter.get_node_range(ctx.query_captures.arguments[1])
      local second_srow, second_scol, _, _ = vim.treesitter.get_node_range(ctx.query_captures.second_argument[1])
      local lines = vim.api.nvim_buf_get_text(0, second_srow, second_scol, args_erow, args_ecol - 1, {})
      return string.format("@first_argument |> @function_name(%s)", table.concat(lines, "\n"))
    end,
    filetype = "elixir",
    description = "Pipe the first argument. Only triggers when the cursor is in the function name",
    example = {
      input = "foo(bar, baz)",
      output = "bar |> foo(baz)",
    },
  },
  {
    input = {
      type = "query",
      pattern = [[
        (binary_operator
          left: (_) @first_argument
          "|>"
          right:
            (call
              target: (_) @function_name
              (arguments) @rest_arguments
            )
        ) @__input__
      ]],
      container = "binary_operator",
    },
    -- Only trigger when the cursor is in the first argument
    trigger = function(ctx)
      local first_argument = ctx.ts_captures.first_argument[1]
      local srow, scol, erow, ecol = vim.treesitter.get_node_range(first_argument)
      return utils.cursor_in_range({ srow, scol, erow, ecol })
    end,
    replacement = function(ctx)
      local rest = vim.treesitter.get_node_text(ctx.query_captures.rest_arguments[1], 0)
      -- Remove the parentheses
      rest = rest:sub(2, -2)

      if rest == "" then
        return "@function_name(@first_argument)"
      else
        return string.format("@function_name(@first_argument, %s)", rest)
      end
    end,
    filetype = "elixir",
    description = "Un-pipe the first argument. Only triggers when the cursor is in the first argument",
    example = {
      input = "bar |> foo(baz)",
      output = "foo(bar, baz)",
    },
  },
}
