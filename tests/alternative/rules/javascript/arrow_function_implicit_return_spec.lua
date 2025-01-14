local alternative = require("alternative")
local helper = require("tests.alternative.helper")

describe("javascript.arrow_function_implicit_return", function()
  describe("converts the arrow function with implicit return to explicit return", function()
    it("only triggers when the cursor is on the arrow (=>) text", function()
      alternative.setup({
        rules = { "javascript.arrow_function_implicit_return" },
      })

      helper.assert_scenario({
        input = [[
          const add = (a, b) =|> a + b
        ]],
        filetype = "javascript",
        action = function()
          alternative.alternate("forward")
        end,
        expected = [[
          const add = (a, b) => {
            return a + b
          }
        ]],
      })

      helper.assert_scenario({
        input = [[
          const add = (a, |b) => a + b
        ]],
        filetype = "javascript",
        action = function()
          alternative.alternate("forward")
        end,
        expected = [[
          const add = (a, b) => a + b
        ]],
      })
    end)
  end)

  describe("converts the arrow function with explicit return to implicit return", function()
    it("only triggers when the block has a single return statement", function()
      alternative.setup({
        rules = { "javascript.arrow_function_implicit_return" },
      })

      helper.assert_scenario({
        input = [[
          const add = (a, b) =|> {
            return a + b
          }
        ]],
        filetype = "javascript",
        action = function()
          alternative.alternate("forward")
        end,
        expected = [[
          const add = (a, b) => a + b
        ]],
      })

      helper.assert_scenario({
        input = [[
          const add = (a, b) =|> {
            console.log(a + b)
            return a + b
          }
        ]],
        filetype = "javascript",
        action = function()
          alternative.alternate("forward")
        end,
        expected = [[
          const add = (a, b) => {
            console.log(a + b)
            return a + b
          }
        ]],
      })
    end)

    it("only triggers when the cursor is on the arrow (=>) text", function()
      alternative.setup({
        rules = { "javascript.arrow_function_implicit_return" },
      })

      helper.assert_scenario({
        input = [[
          const add = (a,| b) => {
            return a + b
          }
        ]],
        filetype = "javascript",
        action = function()
          alternative.alternate("forward")
        end,
        expected = [[
          const add = (a, b) => {
            return a + b
          }
        ]],
      })
    end)
  end)
end)
