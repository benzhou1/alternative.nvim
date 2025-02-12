local alternative = require("alternative")
local helper = require("tests.alternative.helper")

describe("elixir.function_definition_variants", function()
  it("converts function definition from do block to do keyword", function()
    alternative.setup({
      rules = { "elixir.function_definition_variants" },
    })

    helper.assert_scenario({
      input = [[
        d|ef foo do
          bar
        end
      ]],
      filetype = "elixir",
      action = function()
        alternative.alternate("forward")
        helper.wait(10)
      end,
      expected = [[
        def foo, do: bar
      ]],
    })

    helper.assert_scenario({
      input = [[
        d|efp foo do
          bar
        end
      ]],
      filetype = "elixir",
      action = function()
        alternative.alternate("forward")
        helper.wait(10)
      end,
      expected = [[
        defp foo, do: bar
      ]],
    })

    helper.assert_scenario({
      input = [[
        d|efmacro foo do
          bar
        end
      ]],
      filetype = "elixir",
      action = function()
        alternative.alternate("forward")
        helper.wait(10)
      end,
      expected = [[
        defmacro foo, do: bar
      ]],
    })
  end)

  it("converts function definition from do keyword to do block", function()
    alternative.setup({
      rules = { "elixir.function_definition_variants" },
    })

    helper.assert_scenario({
      input = [[
        d|ef foo, do: bar
      ]],
      filetype = "elixir",
      action = function()
        alternative.alternate("forward")
        helper.wait(10)
      end,
      expected = [[
        def foo do
          bar
        end
      ]],
    })

    helper.assert_scenario({
      input = [[
        d|efp foo, do: bar
      ]],
      filetype = "elixir",
      action = function()
        alternative.alternate("forward")
        helper.wait(10)
      end,
      expected = [[
        defp foo do
          bar
        end
      ]],
    })

    helper.assert_scenario({
      input = [[
        d|efmacro foo, do: bar
      ]],
      filetype = "elixir",
      action = function()
        alternative.alternate("forward")
        helper.wait(10)
      end,
      expected = [[
        defmacro foo do
          bar
        end
      ]],
    })
  end)
end)
