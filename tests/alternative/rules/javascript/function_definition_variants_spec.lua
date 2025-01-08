local alternative = require("alternative")
local helper = require("tests.alternative.helper")

describe("javascript.function_definition_variants", function()
  describe("given the input is a function declaration", function()
    it("converts function declaration to function expression", function()
      alternative.setup({
        rules = { "javascript.function_definition_variants" },
      })

      helper.assert_scenario({
        input = [[
          func|tion foo(a, b) {
            return a == b
          }
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
          const foo = function (a, b) {
            return a == b
          }
        ]],
      })
    end)

    it("converts function declaration to arrow function", function()
      alternative.setup({
        rules = { "javascript.function_definition_variants" },
      })

      helper.assert_scenario({
        input = [[
          func|tion foo(a, b) {
            return a == b
          }
        ]],
        filetype = "javascript",
        action = function()
          alternative.alternate("forward")
          alternative.alternate("forward")
          helper.wait(10)

          -- Commit the preview
          vim.api.nvim_input("l")
          helper.wait(10)
        end,
        expected = [[
          const foo = (a, b) => {
            return a == b
          }
        ]],
      })
    end)

    it("only triggers when the cursor is in the function text", function()
      alternative.setup({
        rules = { "javascript.function_definition_variants" },
      })

      helper.assert_scenario({
        input = [[
          function fo|o(a, b) {
            return a == b
          }
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
          function foo(a, b) {
            return a == b
          }
        ]],
      })
    end)
  end)

  describe("given the input is a function expression", function()
    it("converts function expression to function declaration", function()
      alternative.setup({
        rules = { "javascript.function_definition_variants" },
      })

      helper.assert_scenario({
        input = [[
          const foo = func|tion (a, b) {
            return a == b
          }
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
          function foo(a, b) {
            return a == b
          }
        ]],
      })
    end)

    it("converts function expression to arrow function", function()
      alternative.setup({
        rules = { "javascript.function_definition_variants" },
      })

      helper.assert_scenario({
        input = [[
          const foo = func|tion (a, b) {
            return a == b
          }
        ]],
        filetype = "javascript",
        action = function()
          alternative.alternate("forward")
          alternative.alternate("forward")
          helper.wait(10)

          -- Commit the preview
          vim.api.nvim_input("l")
          helper.wait(10)
        end,
        expected = [[
          const foo = (a, b) => {
            return a == b
          }
        ]],
      })
    end)

    it("only triggers when the cursor is in the function text", function()
      alternative.setup({
        rules = { "javascript.function_definition_variants" },
      })

      helper.assert_scenario({
        input = [[
          const fo|o = function (a, b) {
            return a == b
          }
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
          const foo = function (a, b) {
            return a == b
          }
        ]],
      })
    end)
  end)

  describe("given the input is an arrow function", function()
    it("converts arrow function to function declaration", function()
      alternative.setup({
        rules = { "javascript.function_definition_variants" },
      })

      helper.assert_scenario({
        input = [[
          const fo|o = (a, b) => {
            return a == b
          }
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
          function foo(a, b) {
            return a == b
          }
        ]],
      })
    end)

    it("converts arrow function to function expression", function()
      alternative.setup({
        rules = { "javascript.function_definition_variants" },
      })

      helper.assert_scenario({
        input = [[
          const fo|o = (a, b) => {
            return a == b
          }
        ]],
        filetype = "javascript",
        action = function()
          alternative.alternate("forward")
          alternative.alternate("forward")
          helper.wait(10)

          -- Commit the preview
          vim.api.nvim_input("l")
          helper.wait(10)
        end,
        expected = [[
          const foo = function (a, b) {
            return a == b
          }
        ]],
      })
    end)

    it("only triggers when the cursor is in the first line of the input text", function()
      alternative.setup({
        rules = { "javascript.function_definition_variants" },
      })

      helper.assert_scenario({
        input = [[
          const foo = function (a, b) {
            ret|urn a
          }
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
          const foo = function (a, b) {
            return a
          }
        ]],
      })
    end)
  end)
end)
