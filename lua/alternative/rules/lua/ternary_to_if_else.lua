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
  {
    input = {
      type = "query",
      value = [[
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
        ) @input @container
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
  },
  {
    input = {
      type = "query",
      value = [[
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
        ) @input @container
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
  },
}
