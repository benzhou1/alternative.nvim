local alternative = require("alternative")
local helper = require("tests.alternative.helper")

describe("javascript.ternary_to_if_else", function()
  it("converts ternary expression in declaration", function()
    alternative.setup({
      rules = { "javascript.ternary_to_if_else" },
    })

    helper.assert_scenario({
      input = [[
        const foo = a ? b : c
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
        const foo
        if (a) {
          foo = b
        } else {
          foo = c
        }
      ]],
    })
  end)

  it("converts ternary expression in assignment", function()
    alternative.setup({
      rules = { "javascript.ternary_to_if_else" },
    })

    helper.assert_scenario({
      input = [[
        foo = a ? b : c
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
        if (a) {
          foo = b
        } else {
          foo = c
        }
      ]],
    })
  end)

  it("converts ternary expression in return statement", function()
    alternative.setup({
      rules = { "javascript.ternary_to_if_else" },
    })

    helper.assert_scenario({
      input = [[
        return a ? b : c
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
        if (a) {
          return b
        } else {
          return c
        }
      ]],
    })
  end)
end)
