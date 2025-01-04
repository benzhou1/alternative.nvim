local function if_statement_query()
  local clause = function(operator)
    return string.format(
      [[
        (if_statement
          condition:
            (parenthesized_expression
              (binary_expression
                left: (_)
                "%s" @input
                right: (_)
              )
            )
        )
      ]],
      operator
    )
  end

  local operators = { "==", "!=", "===", "!==", ">", "<", ">=", "<=" }
  local clauses = vim.iter(operators):map(clause):totable()
  return table.concat(clauses, "\n")
end

return {
  {
    input = {
      type = "query",
      value = if_statement_query(),
      container = "if_statement",
    },
    replacement = function(ctx)
      local mapping = {
        ["=="] = "!=",
        ["!="] = "==",
        ["==="] = "!==",
        ["!=="] = "===",
        [">"] = "<",
        ["<"] = ">",
        [">="] = "<=",
        ["<="] = ">=",
      }

      return mapping[ctx.original_text[1]]
    end,
    lookahead = true,
    filetype = { "javascript", "typescript", "javascriptreact", "typescriptreact" },
  },
  {
    input = {
      type = "query",
      value = [[
        (if_statement
          condition:
            (parenthesized_expression
              (_) @a
            ) @input
          (#not-type? @a "binary_expression")
        )
      ]],
      container = "if_statement",
    },
    replacement = { "(!@input)" },
    lookahead = true,
    preview = true,
    filetype = { "javascript", "typescript", "javascriptreact", "typescriptreact" },
  },
}
