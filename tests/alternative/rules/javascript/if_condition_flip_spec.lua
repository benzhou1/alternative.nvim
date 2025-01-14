local alternative = require("alternative")
local helper = require("tests.alternative.helper")

describe("javascript.if_condition_flip", function()
  it("flips the condition of if statement", function()
    alternative.setup({
      rules = { "javascript.if_condition_flip" },
    })

    helper.assert_scenario({
      input = [[
        if (f|oo == bar) then
        end
      ]],
      filetype = "javascript",
      action = function()
        alternative.alternate("forward")
      end,
      expected = [[
        if (foo != bar) then
        end
      ]],
    })

    helper.assert_scenario({
      input = [[
        if (f|oo != bar) then
        end
      ]],
      filetype = "javascript",
      action = function()
        alternative.alternate("forward")
      end,
      expected = [[
        if (foo == bar) then
        end
      ]],
    })

    helper.assert_scenario({
      input = [[
        if (f|oo === bar) then
        end
      ]],
      filetype = "javascript",
      action = function()
        alternative.alternate("forward")
      end,
      expected = [[
        if (foo !== bar) then
        end
      ]],
    })

    helper.assert_scenario({
      input = [[
        if (f|oo !== bar) then
        end
      ]],
      filetype = "javascript",
      action = function()
        alternative.alternate("forward")
      end,
      expected = [[
        if (foo === bar) then
        end
      ]],
    })

    helper.assert_scenario({
      input = [[
        if (f|oo > bar) then
        end
      ]],
      filetype = "javascript",
      action = function()
        alternative.alternate("forward")
      end,
      expected = [[
        if (foo < bar) then
        end
      ]],
    })

    helper.assert_scenario({
      input = [[
        if (f|oo > bar) then
        end
      ]],
      filetype = "javascript",
      action = function()
        alternative.alternate("forward")
      end,
      expected = [[
        if (foo < bar) then
        end
      ]],
    })

    helper.assert_scenario({
      input = [[
        if (f|oo >= bar) then
        end
      ]],
      filetype = "javascript",
      action = function()
        alternative.alternate("forward")
      end,
      expected = [[
        if (foo <= bar) then
        end
      ]],
    })

    helper.assert_scenario({
      input = [[
        if (f|oo >= bar) then
        end
      ]],
      filetype = "javascript",
      action = function()
        alternative.alternate("forward")
      end,
      expected = [[
        if (foo <= bar) then
        end
      ]],
    })
  end)

  it("adds negate operator to the condition of if statement", function()
    alternative.setup({
      rules = { "javascript.if_condition_flip" },
    })

    helper.assert_scenario({
      input = [[
        i|f (foo) then
        end
      ]],
      filetype = "javascript",
      action = function()
        alternative.alternate("forward")
        helper.wait(10)

        -- Commit the preview
        vim.api.nvim_input("l")
        helper.wait(10)
      end,
      expected = [[
        if (!(foo)) then
        end
      ]],
    })
  end)

  it("removes negate operator of the condition of if statement if it is already there", function()
    alternative.setup({
      rules = { "javascript.if_condition_flip" },
    })

    helper.assert_scenario({
      input = [[
        i|f (!foo) then
        end
      ]],
      filetype = "javascript",
      action = function()
        alternative.alternate("forward")
        helper.wait(10)

        -- Commit the preview
        vim.api.nvim_input("l")
        helper.wait(10)
      end,
      expected = [[
        if (foo) then
        end
      ]],
    })
  end)
end)
