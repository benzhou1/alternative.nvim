return {
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
      local mapping = {
        ["~="] = "==",
        ["=="] = "~=",
        [">"] = "<",
        ["<"] = ">",
        [">="] = "<=",
        ["<="] = ">=",
      }

      return mapping[ctx.original_text[1]]
    end,
    lookahead = true,
    filetype = "lua",
  },
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
