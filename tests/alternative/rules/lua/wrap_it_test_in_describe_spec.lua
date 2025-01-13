local alternative = require("alternative")
local helper = require("tests.alternative.helper")

describe("lua.wrap_it_test_in_describe", function()
  it("wraps the Lua it function in describe function", function()
    alternative.setup({
      rules = { "lua.wrap_it_test_in_describe" },
    })

    helper.assert_scenario({
      input = [[
        i|t("should log", function()
          print("foo")
        end)
      ]],
      filetype = "lua",
      action = function()
        -- Only trigger for test files
        vim.api.nvim_buf_set_name(0, "test.lua")

        alternative.alternate("forward")
        helper.wait(10)

        -- Commit the preview
        vim.api.nvim_input("l")
        helper.wait(10)
      end,
      expected = [[
        describe("should log", function()
          it("", function()
          print("foo")
        end)
        end)
      ]],
    })
  end)

  it("only triggers for files with name matching test.lua or spec.lua", function()
    alternative.setup({
      rules = { "lua.wrap_it_test_in_describe" },
    })

    helper.assert_scenario({
      input = [[
        i|t("should log", function()
          print("foo")
        end)
      ]],
      filetype = "lua",
      action = function()
        vim.api.nvim_buf_set_name(0, "something.lua")

        alternative.alternate("forward")
        helper.wait(10)

        -- Commit the preview
        vim.api.nvim_input("l")
        helper.wait(10)
      end,
      expected = [[
        it("should log", function()
          print("foo")
        end)
      ]],
    })
  end)
end)
