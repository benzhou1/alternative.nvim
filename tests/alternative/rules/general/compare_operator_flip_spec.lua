local alternative = require("alternative")
local helper = require("tests.alternative.helper")

describe("general.compare_operator_flip", function()
  it("converts general compare operator to its opposite", function()
    alternative.setup({
      rules = { "general.compare_operator_flip" },
    })

    helper.assert_scenario({
      input = [[
        local foo = 2 > 1
      ]],
      filetype = "lua",
      action = function()
        alternative.alternate("forward")
      end,
      expected = [[
        local foo = 2 < 1
      ]],
    })

    helper.assert_scenario({
      input = [[
        local foo = 2 < 1
      ]],
      filetype = "lua",
      action = function()
        alternative.alternate("forward")
      end,
      expected = [[
        local foo = 2 > 1
      ]],
    })

    helper.assert_scenario({
      input = [[
        local foo = 2 >= 1
      ]],
      filetype = "lua",
      action = function()
        alternative.alternate("forward")
      end,
      expected = [[
        local foo = 2 <= 1
      ]],
    })

    helper.assert_scenario({
      input = [[
        local foo = 2 <= 1
      ]],
      filetype = "lua",
      action = function()
        alternative.alternate("forward")
      end,
      expected = [[
        local foo = 2 >= 1
      ]],
    })
  end)

  it("converts lua compare operator to its opposite", function()
    alternative.setup({
      rules = { "general.compare_operator_flip" },
    })

    helper.assert_scenario({
      input = [[
        local foo = 2 == 1
      ]],
      filetype = "lua",
      action = function()
        alternative.alternate("forward")
      end,
      expected = [[
        local foo = 2 ~= 1
      ]],
    })

    helper.assert_scenario({
      input = [[
        local foo = 2 ~= 1
      ]],
      filetype = "lua",
      action = function()
        alternative.alternate("forward")
      end,
      expected = [[
        local foo = 2 == 1
      ]],
    })
  end)

  it("converts javascript compare operator to its opposite", function()
    alternative.setup({
      rules = { "general.compare_operator_flip" },
    })

    helper.assert_scenario({
      input = [[
        local foo = 2 == 1
      ]],
      filetype = "javascript",
      action = function()
        alternative.alternate("forward")
      end,
      expected = [[
        local foo = 2 != 1
      ]],
    })

    helper.assert_scenario({
      input = [[
        local foo = 2 != 1
      ]],
      filetype = "javascript",
      action = function()
        alternative.alternate("forward")
      end,
      expected = [[
        local foo = 2 == 1
      ]],
    })

    helper.assert_scenario({
      input = [[
        local foo = 2 !== 1
      ]],
      filetype = "javascript",
      action = function()
        alternative.alternate("forward")
      end,
      expected = [[
        local foo = 2 === 1
      ]],
    })

    helper.assert_scenario({
      input = [[
        local foo = 2 !== 1
      ]],
      filetype = "javascript",
      action = function()
        alternative.alternate("forward")
      end,
      expected = [[
        local foo = 2 === 1
      ]],
    })
  end)
end)
