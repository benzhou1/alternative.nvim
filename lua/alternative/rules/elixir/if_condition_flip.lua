return {
  {
    input = {
      type = "query",
      pattern = [[
        (
          (call
            target: (identifier) @identifier
            (arguments
              [
                (identifier)
                (call)
              ] @__input__
            )
          )
          (#eq? @identifier "if")
        )
      ]],
      container = "call",
    },
    replacement = { "not @__input__", "!@__input__" },
    preview = true,
    filetype = "elixir",
    description = "Append not or negate",
    example = {
      input = "if foo, do: bar",
      output = "if not foo, do: bar",
    },
  },
  {
    input = {
      type = "query",
      pattern = [[
        (
          (call
            target: (identifier) @identifier
            (arguments
              (unary_operator
                operand: (_) @condition
              ) @__input__
            )
          )
          (#eq? @identifier "if")
        )
      ]],
      container = "call",
    },
    replacement = "@condition",
    filetype = "elixir",
    description = "Remove not or negate",
    example = {
      input = "if not foo, do: bar",
      output = "if foo, do: bar",
    },
  },
}
