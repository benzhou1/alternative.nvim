local base = {
  {
    input = {
      type = "query",
      value = [[
        (if_statement
          condition: (binary_expression
            left: (_)
            "==" @input
            right: (_)
          )
        ) @container

        (if_statement
          condition: (binary_expression
            left: (_)
            "~=" @input
            right: (_)
          )
        ) @container

        (if_statement
          condition: (binary_expression
            left: (_)
            ">" @input
            right: (_)
          )
        ) @container

        (if_statement
          condition: (binary_expression
            left: (_)
            "<" @input
            right: (_)
          )
        ) @container

        (if_statement
          condition: (binary_expression
            left: (_)
            ">=" @input
            right: (_)
          )
        ) @container

        (if_statement
          condition: (binary_expression
            left: (_)
            "<=" @input
            right: (_)
          )
        ) @container
      ]],
      container = "if_statement",
    },
    replacement = function(ctx)
      if ctx.original_text[1] == "==" then
        return "~="
      elseif ctx.original_text[1] == "~=" then
        return "=="
      elseif ctx.original_text[1] == ">" then
        return "<"
      elseif ctx.original_text[1] == "<" then
        return ">"
      elseif ctx.original_text[1] == ">=" then
        return "<="
      elseif ctx.original_text[1] == "<=" then
        return ">="
      end

      return {}
    end,
    lookahead = true,
    filetype = "lua",
  },
}

local lua = {
  {
    input = {
      type = "query",
      value = [[
        (if_statement
          condition: (_) @input
          (#not-type? @input "binary_expression")
        ) @container
      ]],
      container = "if_statement",
    },
    replacement = { "not (@input)" },
    lookahead = true,
    preview = true,
    filetype = "lua",
  },
}

local javascript = {
  {
    input = {
      type = "query",
      value = [[
        (if_statement
          condition: (_) @input
          (#not-type? @input "binary_expression")
        ) @container
      ]],
      container = "if_statement",
    },
    replacement = { "(!@input)" },
    lookahead = true,
    preview = true,
    filetype = { "javascript", "typescript", "javascriptreact", "typescriptreact" },
  },
}

return vim.iter({ base, lua, javascript }):flatten():totable()
