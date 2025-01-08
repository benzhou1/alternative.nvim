local utils = require("alternative.utils")

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
    replacement = {
      "const @name = function @parameters @body",
      "const @name = @parameters => @body",
    },
    filetype = { "javascript", "javascriptreact" },
    description = "Convert function declaration to function expression or arrow function",
    note = "Only triggers when the cursor is in the `function` text",
    example = {
      input = utils.format_indentation([[
        func|tion foo(a, b) {
          return a == b
        }
      ]]),
      output = utils.format_indentation([[
        const foo = function (a, b) {
          return a == b
        }

        // Or

        const foo = (a, b) => {
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
    replacement = {
      "function @name@parameters @body",
      "const @name = @parameters => @body",
    },
    filetype = { "javascript", "javascriptreact" },
    description = "Convert function expression to function declaration or arrow function",
    note = "Only triggers when the cursor is in the `function` text",
    example = {
      input = utils.format_indentation([[
        const foo = func|tion (a, b) {
          return a == b
        }
      ]]),
      output = utils.format_indentation([[
        function foo(a, b) {
          return a == b
        }

        // Or

        const foo = (a, b) => {
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
            )
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
    replacement = {
      "function @name@parameters @body",
      "const @name = function @parameters @body",
    },
    filetype = { "javascript", "javascriptreact" },
    description = "Convert arrow function to function declaration or function expression",
    note = "Only triggers when the cursor is in the first line the the function definition",
    example = {
      input = utils.format_indentation([[
        con|st foo = (a, b) => {
          return a == b
        }
      ]]),
      output = utils.format_indentation([[
        function foo(a, b) {
          return a == b
        }

        // Or

        const foo = function (a, b) {
          return a == b
        }
      ]]),
    },
  },
}
