local utils = require("alternative.utils")

return {
  {
    input = {
      type = "query",
      pattern = [[
        (variable_declaration
          (assignment_statement
            (variable_list) @variable
            (expression_list
              value: (binary_expression
               left:
                 (binary_expression
                   left: (_) @condition
                   "and"
                   right: (_) @and
                 )
               "or"
               right: (_) @or
              )
            )
          )
        ) @__input__
      ]],
      container = "variable_declaration",
    },
    replacement = utils.format_indentation([[
      local @variable
      if @condition then
        @variable = @and
      else
        @variable = @or
      end
    ]]),
    preview = true,
    filetype = "lua",
    description = "Convert ternary expression in declaration",
    example = {
      input = utils.format_indentation([[
        local fo|o = a and b or c
      ]]),
      output = utils.format_indentation([[
        local foo
        if a then
          foo = b
        else
          foo = c
        end
      ]]),
    },
  },
  {
    input = {
      type = "query",
      pattern = [[
        (
          (assignment_statement
            (variable_list) @variable
            (expression_list
              value: (binary_expression
               left:
                 (binary_expression
                   left: (_) @condition
                   "and"
                   right: (_) @and
                 )
               "or"
               right: (_) @or
             )
            )
          ) @__input__
          (#not-has-parent? @__input__ variable_declaration)
        )
      ]],
      container = "assignment_statement",
    },
    replacement = utils.format_indentation([[
      if @condition then
        @variable = @and
      else
        @variable = @or
      end
    ]]),
    preview = true,
    filetype = "lua",
    description = "Convert ternary expression in assignment",
    example = {
      input = utils.format_indentation([[
        fo|o = a and b or c
      ]]),
      output = utils.format_indentation([[
        if a then
          foo = b
        else
          foo = c
        end
      ]]),
    },
  },
  {
    input = {
      type = "query",
      pattern = [[
        (return_statement
          (expression_list
            (binary_expression
              left: (binary_expression
                left: (_) @condition
                "and"
                right: (_) @and
              )
              "or"
              right: (_) @or
            )
          )
        ) @__input__
      ]],
      container = "return_statement",
    },
    replacement = utils.format_indentation([[
      if @condition then
        return @and
      else
        return @or
      end
    ]]),
    preview = true,
    filetype = "lua",
    description = "Convert ternary expression in return statement",
    example = {
      input = utils.format_indentation([[
        return a and b or c
      ]]),
      output = utils.format_indentation([[
        if a then
          return b
        else
          return c
        end
      ]]),
    },
  },
}
