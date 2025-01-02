local utils = require("alternative.utils")

return {
  {
    input = {
      type = "query",
      value = [[
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
        ) @input @container
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
  },
}
