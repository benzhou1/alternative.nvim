local lua = {
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
  replacement = [[
local @variable
if @condition then
  @variable = @and
else
  @variable = @or
end]],
  preview = true,
  filetype = "lua",
}

local javascript = {
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
  replacement = [[
const @variable
if @condition {
  @variable = @consequence
} else {
  @variable = @alternative
}]],
  preview = true,
  filetype = { "javascript", "typescript", "javascriptreact", "typescriptreact" },
}

return { lua, javascript }
