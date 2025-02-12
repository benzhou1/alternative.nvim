local alternative = require("alternative")
local helper = require("tests.alternative.helper")

describe("elixir.if_expression_variants", function()
  it("converts if expression from long form to short form", function()
    alternative.setup({
      rules = { "elixir.if_expression_variants" },
    })

    helper.assert_scenario({
      input = [[
        i|f foo do
          bar
        end
      ]],
      filetype = "elixir",
      action = function()
        alternative.alternate("forward")
        helper.wait(10)
      end,
      expected = [[
        if foo, do: bar
      ]],
    })
  end)

  it("converts if/else expression from long form to short form", function()
    alternative.setup({
      rules = { "elixir.if_expression_variants" },
    })

    helper.assert_scenario({
      input = [[
        i|f foo do
          bar
        else
          baz
        end
      ]],
      filetype = "elixir",
      action = function()
        alternative.alternate("forward")
        helper.wait(10)
      end,
      expected = [[
        if foo, do: bar, else: baz
      ]],
    })
  end)

  it("converts if expression from short form to long form", function()
    alternative.setup({
      rules = { "elixir.if_expression_variants" },
    })

    helper.assert_scenario({
      input = [[
        i|f foo, do: bar
      ]],
      filetype = "elixir",
      action = function()
        alternative.alternate("forward")
        helper.wait(10)
      end,
      expected = [[
        if foo do
          bar
        end
      ]],
    })
  end)

  it("converts if/else expression from short form to long form", function()
    alternative.setup({
      rules = { "elixir.if_expression_variants" },
    })

    helper.assert_scenario({
      input = [[
        i|f foo, do: bar, else: baz
      ]],
      filetype = "elixir",
      action = function()
        alternative.alternate("forward")
        helper.wait(10)
      end,
      expected = [[
        if foo do
          bar
        else
          baz
        end
      ]],
    })
  end)
end)
