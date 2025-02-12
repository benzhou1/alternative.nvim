local utils = require("alternative.utils")

return {
  {
    input = {
      type = "query",
      -- Match if expressions that have single expression body
      pattern = [[
        (
          (call
            target: (identifier) @identifier
            (arguments
              .
              (_) @function_head
              .
            )
            (do_block
              .
              (_) @do_body
              .
            )
          ) @__input__
          (#any-of? @identifier "def" "defp" "defmacro")
        )
      ]],
      container = "call",
      lookahead = true,
    },
    replacement = "@identifier @function_head, do: @do_body",
    filetype = "elixir",
    description = "function definition: do block to do keyword",
    example = {
      input = utils.format_indentation([[
        def foo do
          bar
        end
      ]]),
      output = "def foo, do: bar",
    },
  },
  {
    input = {
      type = "query",
      -- Match if expressions that have single expression body
      pattern = [[
        (
          (call
            target: (identifier) @identifier
            (arguments
              .
              (_) @function_head
              (keywords
                .
                (pair
                  key: (keyword) @key
                  value: (_) @do_body
                )
                .
              )
              .
            )
          ) @__input__
          (#any-of? @identifier "def" "defp" "defmacro")
          (#match? @key "^do")
        )
      ]],
      container = "call",
      lookahead = true,
    },
    replacement = utils.format_indentation([[
      @identifier @function_head do
        @do_body
      end
    ]]),
    filetype = "elixir",
    description = "function definition: do keyword to do block",
    example = {
      input = "def foo, do: bar",
      output = utils.format_indentation([[
        def foo do
          bar
        end
      ]]),
    },
  },
}
