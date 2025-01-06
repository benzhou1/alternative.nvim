local alternative = require("alternative")
local helper = require("tests.alternative.helper")

describe("general.boolean_flip", function()
  it("converts true to false", function()
    alternative.setup({
      rules = { "general.boolean_flip" },
    })

    helper.assert_scenario({
      input = [[
        local foo = tr|ue
      ]],
      filetype = "lua",
      action = function()
        alternative.alternate("forward")
      end,
      expected = [[
        local foo = false
      ]],
    })

    helper.assert_scenario({
      input = [[
        local fo|o = true
      ]],
      filetype = "lua",
      action = function()
        alternative.alternate("forward")
      end,
      expected = [[
        local foo = false
      ]],
    })
  end)

  it("converts false to true", function()
    alternative.setup({
      rules = { "general.boolean_flip" },
    })

    helper.assert_scenario({
      input = [[
        local foo = fal|se
      ]],
      filetype = "lua",
      action = function()
        alternative.alternate("forward")
      end,
      expected = [[
        local foo = true
      ]],
    })

    helper.assert_scenario({
      input = [[
        local fo|o = false
      ]],
      filetype = "lua",
      action = function()
        alternative.alternate("forward")
      end,
      expected = [[
        local foo = true
      ]],
    })
  end)
end)
