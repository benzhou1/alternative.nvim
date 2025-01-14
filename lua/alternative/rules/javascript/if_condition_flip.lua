local utils = require("alternative.utils")

local function if_statement_query()
  local clause = function(operator)
    return string.format(
      [[
        (if_statement
          condition:
            (parenthesized_expression
              (binary_expression
                left: (_)
                "%s" @__input__
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
      pattern = if_statement_query(),
      container = "if_statement",
      lookahead = true,
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
    filetype = { "javascript", "typescript", "javascriptreact", "typescriptreact" },
    description = "Flip the compare operator",
    example = {
      input = utils.format_indentation([[
        if (a| == b) {
          return true
        }
      ]]),
      output = utils.format_indentation([[
        if (a != b) {
          return true
        }
      ]]),
    },
  },
  {
    input = {
      type = "query",
      pattern = [[
        (if_statement
          condition:
            (parenthesized_expression
              (_) @a
            ) @__input__
          (#not-type? @a "binary_expression")
          (#not-type? @a "unary_expression")
        )
      ]],
      container = "if_statement",
      lookahead = true,
    },
    replacement = { "(!@__input__)" },
    preview = true,
    filetype = { "javascript", "typescript", "javascriptreact", "typescriptreact" },
    description = "Use negation operator",
    example = {
      input = utils.format_indentation([[
        i|f (foo(bar, baz)) {
          return true
        }
      ]]),
      output = utils.format_indentation([[
        if (!(foo(bar, baz))) {
          return true
        }
      ]]),
    },
  },
  {
    input = {
      type = "query",
      pattern = [[
        (if_statement
          condition:
            (parenthesized_expression
              (unary_expression
                argument: (_) @a
              )
            ) @__input__
        )
      ]],
      container = "if_statement",
      lookahead = true,
    },
    replacement = { "(@a)" },
    preview = true,
    filetype = { "javascript", "typescript", "javascriptreact", "typescriptreact" },
    description = "Remove negation operator",
    example = {
      input = utils.format_indentation([[
        i|f (!foo(bar, baz)) {
          return true
        }
      ]]),
      output = utils.format_indentation([[
        if (foo(bar, baz)) {
          return true
        }
      ]]),
    },
  },
}
