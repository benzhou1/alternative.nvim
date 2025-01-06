local alternative = require("alternative")
local helper = require("tests.alternative.helper")

describe("lua.ternary_to_if_else", function()
  it("converts ternary expression in declaration", function()
    alternative.setup({
      rules = { "lua.ternary_to_if_else" },
    })

    helper.assert_scenario({
      input = [[
        local fo|o = a and b or c
      ]],
      filetype = "lua",
      action = function()
        alternative.alternate("forward")
        helper.wait(10)

        -- Commit the preview
        vim.api.nvim_input("l")
        helper.wait(10)
      end,
      expected = [[
        local foo
        if a then
          foo = b
        else
          foo = c
        end
      ]],
    })
  end)

  it("converts ternary expression in assignment", function()
    alternative.setup({
      rules = { "lua.ternary_to_if_else" },
    })

    helper.assert_scenario({
      input = [[
        fo|o = a and b or c
      ]],
      filetype = "lua",
      action = function()
        alternative.alternate("forward")
        helper.wait(10)

        -- Commit the preview
        vim.api.nvim_input("l")
        helper.wait(10)
      end,
      expected = [[
        if a then
          foo = b
        else
          foo = c
        end
      ]],
    })
  end)

  it("converts ternary expression in return statement", function()
    alternative.setup({
      rules = { "lua.ternary_to_if_else" },
    })

    helper.assert_scenario({
      input = [[
        return a and b or c
      ]],
      filetype = "lua",
      action = function()
        alternative.alternate("forward")
        helper.wait(10)

        -- Commit the preview
        vim.api.nvim_input("l")
        helper.wait(10)
      end,
      expected = [[
        if a then
          return b
        else
          return c
        end
      ]],
    })
  end)
end)
