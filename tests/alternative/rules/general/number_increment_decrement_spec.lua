local alternative = require("alternative")
local helper = require("tests.alternative.helper")

describe("general.number_increment_decrement", function()
  it("increments number", function()
    alternative.setup({
      rules = { "general.number_increment_decrement" },
    })

    helper.assert_scenario({
      input = [[
        local foo = 1|
      ]],
      filetype = "lua",
      action = function()
        alternative.alternate("forward")
      end,
      expected = [[
        local foo = 2
      ]],
    })

    helper.assert_scenario({
      input = [[
        local fo|o = 1
      ]],
      filetype = "lua",
      action = function()
        alternative.alternate("forward")
      end,
      expected = [[
        local foo = 2
      ]],
    })
  end)

  it("decrements number", function()
    alternative.setup({
      rules = { "general.number_increment_decrement" },
    })

    helper.assert_scenario({
      input = [[
        local foo = 1|
      ]],
      filetype = "lua",
      action = function()
        alternative.alternate("backward")
      end,
      expected = [[
        local foo = 0
      ]],
    })

    helper.assert_scenario({
      input = [[
        local fo|o = 1
      ]],
      filetype = "lua",
      action = function()
        alternative.alternate("backward")
      end,
      expected = [[
        local foo = 0
      ]],
    })
  end)
end)
