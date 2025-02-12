local alternative = require("alternative")
local helper = require("tests.alternative.helper")

describe("elixir.if_condition_flip", function()
  it("adds not to the condition of if statement", function()
    alternative.setup({
      rules = { "elixir.if_condition_flip" },
    })

    helper.assert_scenario({
      input = [[
        if fo|o, do: bar
      ]],
      filetype = "elixir",
      action = function()
        alternative.alternate("forward")
        helper.wait(10)

        -- Commit the preview
        vim.api.nvim_input("l")
        helper.wait(10)
      end,
      expected = [[
        if not foo, do: bar
      ]],
    })

    helper.assert_scenario({
      input = [[
        if fo|o, do: bar
      ]],
      filetype = "elixir",
      action = function()
        -- Select the second variant
        alternative.alternate("forward")
        alternative.alternate("forward")
        helper.wait(10)

        -- Commit the preview
        vim.api.nvim_input("l")
        helper.wait(10)
      end,
      expected = [[
        if !foo, do: bar
      ]],
    })
  end)

  it("removes not from the condition of if statement if it is already there", function()
    alternative.setup({
      rules = { "elixir.if_condition_flip" },
    })

    helper.assert_scenario({
      input = [[
        if not f|oo, do: bar
      ]],
      filetype = "elixir",
      action = function()
        alternative.alternate("forward")
        helper.wait(10)

        -- Commit the preview
        vim.api.nvim_input("l")
        helper.wait(10)
      end,
      expected = [[
        if foo, do: bar
      ]],
    })

    helper.assert_scenario({
      input = [[
        if !fo|o, do: bar
      ]],
      filetype = "elixir",
      action = function()
        alternative.alternate("forward")
        helper.wait(10)

        -- Commit the preview
        vim.api.nvim_input("l")
        helper.wait(10)
      end,
      expected = [[
        if foo, do: bar
      ]],
    })
  end)
end)
