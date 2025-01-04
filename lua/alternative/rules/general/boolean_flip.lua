return {
  input = {
    type = "strings",
    value = { "true", "false" },
  },
  replacement = function(ctx)
    local mapping = {
      ["true"] = "false",
      ["false"] = "true",
    }

    return mapping[ctx.original_text[1]]
  end,
  lookahead = true,
}
