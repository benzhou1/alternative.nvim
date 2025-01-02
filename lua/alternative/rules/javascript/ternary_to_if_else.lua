local utils = require("alternative.utils")

return {
  {
    input = {
      type = "query",
      value = [[
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
        ) @input @container
      ]],
      container = "lexical_declaration",
    },
    replacement = {
      utils.format_indentation([[
        const @variable
        if (@condition) {
          @variable = @consequence
        } else {
          @variable = @alternative
        }
      ]]),
      utils.format_indentation([[
        const @variable = @condition ? @alternative : @consequence
      ]]),
    },
    preview = true,
    filetype = { "javascript", "typescript", "javascriptreact", "typescriptreact" },
  },
  {
    input = {
      type = "query",
      value = [[
        (assignment_expression
          left: (_) @variable
          right:
            (ternary_expression
              condition: (_) @condition
              consequence: (_) @consequence
              alternative: (_) @alternative
            )
        ) @input @container
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
  },
}
