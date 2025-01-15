local stub = require("luassert.stub")
local alternative = require("alternative")
local preview = require("alternative.preview")
local helper = require("tests.alternative.helper")

describe("config", function()
  it("supports built-in rules", function()
    alternative.setup({
      rules = { "general.boolean_flip" },
    })

    helper.assert_scenario({
      input = "local fo|o = true",
      filetype = "lua",
      action = function()
        alternative.alternate("forward")
      end,
      expected = "local foo = false",
    })
  end)

  it("supports overriding built-in rules", function()
    alternative.setup({
      rules = { ["general.boolean_flip"] = {
        replacement = "falsy",
      } },
    })

    helper.assert_scenario({
      input = "local fo|o = true",
      filetype = "lua",
      action = function()
        alternative.alternate("forward")
      end,
      expected = "local foo = falsy",
    })
  end)

  it("supports custom rules", function()
    alternative.setup({
      rules = {
        custom = {
          hello_world = {
            input = { type = "string", pattern = "hello", lookahead = true },
            replacement = "world",
          },
        },
      },
    })

    helper.assert_scenario({
      input = [[
        local fo|o = "hello"
      ]],
      filetype = "lua",
      action = function()
        alternative.alternate("forward")
      end,
      expected = [[
        local foo = "world"
      ]],
    })
  end)

  it("allows customize select labels", function()
    alternative.setup({
      rules = {
        custom = {
          zero_to_one = {
            input = { type = "string", pattern = "0", lookahead = true },
            replacement = "1",
          },
          one_to_zero = {
            input = { type = "string", pattern = "1", lookahead = true },
            replacement = "0",
          },
        },
      },
      select_labels = "xyz",
    })

    stub(vim.fn, "getcharstr")

    helper.assert_scenario({
      input = [[
        local fo|o = "01"
      ]],
      filetype = "lua",
      action = function()
        ---@diagnostic disable-next-line: undefined-field
        vim.fn.getcharstr.returns("x")
        alternative.alternate("forward")
      end,
      expected = [[
        local foo = "11"
      ]],
    })

    helper.assert_scenario({
      input = [[
        local fo|o = "01"
      ]],
      filetype = "lua",
      action = function()
        ---@diagnostic disable-next-line: undefined-field
        vim.fn.getcharstr.returns("y")
        alternative.alternate("forward")
      end,
      expected = [[
        local foo = "00"
      ]],
    })

    ---@diagnostic disable-next-line: undefined-field
    vim.fn.getcharstr:revert()
  end)
end)

describe("string type input", function()
  describe("given lookahead is false", function()
    it("matches the current word as input", function()
      alternative.setup({
        rules = {
          custom = {
            hello_world = {
              input = { type = "string", pattern = "hello", lookahead = false },
              replacement = "world",
            },
          },
        },
      })

      helper.assert_scenario({
        input = [[
          local fo|o = "hello"
        ]],
        filetype = "lua",
        action = function()
          alternative.alternate("forward")
        end,
        expected = [[
          local foo = "hello"
        ]],
      })

      helper.assert_scenario({
        input = [[
          local foo = "hel|lo"
        ]],
        filetype = "lua",
        action = function()
          alternative.alternate("forward")
        end,
        expected = [[
          local foo = "world"
        ]],
      })
    end)
  end)

  describe("given lookahead is true", function()
    it("looks ahead from the cursor position to find the input", function()
      alternative.setup({
        rules = {
          custom = {
            hello_world = {
              input = { type = "string", pattern = "hello", lookahead = true },
              replacement = "world",
            },
          },
        },
      })

      helper.assert_scenario({
        input = [[
          local fo|o = "hello"
        ]],
        filetype = "lua",
        action = function()
          alternative.alternate("forward")
        end,
        expected = [[
          local foo = "world"
        ]],
      })
    end)
  end)
end)

describe("strings type input", function()
  it("matches any of the string in the list", function()
    alternative.setup({
      rules = {
        custom = {
          hello_world = {
            input = { type = "strings", pattern = { "hello", "world" }, lookahead = true },
            replacement = "goodbye",
          },
        },
      },
    })

    helper.assert_scenario({
      input = [[
        local fo|o = "hello"
      ]],
      filetype = "lua",
      action = function()
        alternative.alternate("forward")
      end,
      expected = [[
        local foo = "goodbye"
      ]],
    })

    helper.assert_scenario({
      input = [[
        local foo = "wor|ld"
      ]],
      filetype = "lua",
      action = function()
        alternative.alternate("forward")
      end,
      expected = [[
        local foo = "goodbye"
      ]],
    })
  end)
end)

describe("query type input", function()
  describe("given the cursor position is within the container node", function()
    it("matches the input using the given query", function()
      alternative.setup({
        rules = {
          custom = {
            hello_world = {
              input = {
                type = "query",
                pattern = [[
                  (expression_list
                    value: (string
                      content: (string_content)
                    )
                  ) @__input__
                ]],
                lookahead = true,
                container = "expression_list",
              },
              replacement = [["to anything else"]],
            },
          },
        },
      })

      helper.assert_scenario({
        input = [[
          local foo = "anyth|ing"
        ]],
        filetype = "lua",
        action = function()
          alternative.alternate("forward")
        end,
        expected = [[
          local foo = "to anything else"
        ]],
      })
    end)
  end)

  describe("given the cursor position is NOT within the container node", function()
    it("DOES NOT match the input", function()
      alternative.setup({
        rules = {
          custom = {
            hello_world = {
              input = {
                type = "query",
                pattern = [[
                  (expression_list
                    value: (string
                      content: (string_content)
                    )
                  ) @__input__
                ]],
                lookahead = true,
                container = "expression_list",
              },
              replacement = [["to anything else"]],
            },
          },
        },
      })

      helper.assert_scenario({
        input = [[
          local fo|o = "anything"
        ]],
        filetype = "lua",
        action = function()
          alternative.alternate("forward")
        end,
        expected = [[
          local foo = "anything"
        ]],
      })
    end)
  end)

  describe("given the lookahead is false", function()
    it("only matches when the cursor is within the __input__ capture", function()
      alternative.setup({
        rules = {
          custom = {
            hello_world = {
              input = {
                type = "query",
                pattern = [[
                  (assignment_statement
                    (variable_list)
                    (expression_list
                      value: (string
                        content: (string_content)
                      )
                    ) @__input__
                  )
                ]],
                lookahead = false,
                container = "assignment_statement",
              },
              replacement = [["to anything else"]],
            },
          },
        },
      })

      helper.assert_scenario({
        input = [[
          local fo|o = "anything"
        ]],
        filetype = "lua",
        action = function()
          alternative.alternate("forward")
        end,
        expected = [[
          local foo = "anything"
        ]],
      })
    end)
  end)

  describe("given the lookahead is false", function()
    it("only matches when the cursor is within the __input__ capture", function()
      alternative.setup({
        rules = {
          custom = {
            hello_world = {
              input = {
                type = "query",
                pattern = [[
                  (assignment_statement
                    (variable_list)
                    (expression_list
                      value: (string
                        content: (string_content)
                      )
                    ) @__input__
                  )
                ]],
                lookahead = false,
                container = "assignment_statement",
              },
              replacement = [["to anything else"]],
            },
          },
        },
      })

      helper.assert_scenario({
        input = [[
          local fo|o = "anything"
        ]],
        filetype = "lua",
        action = function()
          alternative.alternate("forward")
        end,
        expected = [[
          local foo = "anything"
        ]],
      })
    end)
  end)

  describe("given the lookahead is true", function()
    it("matches when the cursor is before the __input__ capture", function()
      alternative.setup({
        rules = {
          custom = {
            hello_world = {
              input = {
                type = "query",
                pattern = [[
                  (assignment_statement
                    (variable_list)
                    (expression_list
                      value: (string
                        content: (string_content)
                      )
                    ) @__input__
                  )
                ]],
                lookahead = true,
                container = "assignment_statement",
              },
              replacement = [["to anything else"]],
            },
          },
        },
      })

      helper.assert_scenario({
        input = [[
          local fo|o = "anything"
        ]],
        filetype = "lua",
        action = function()
          alternative.alternate("forward")
        end,
        expected = [[
          local foo = "to anything else"
        ]],
      })
    end)
  end)
end)

describe("callback type input", function()
  it("calls the callback to resolve the input", function()
    alternative.setup({
      rules = {
        custom = {
          hello_world = {
            input = {
              type = "callback",
              pattern = function()
                return { 0, 0, 0, 5 }
              end,
            },
            replacement = "world",
          },
        },
      },
    })

    helper.assert_scenario({
      input = [[
        local foo = "hello"
        local ba|r = "world"
      ]],
      filetype = "lua",
      action = function()
        alternative.alternate("forward")
      end,
      expected = [[
        world foo = "hello"
        local bar = "world"
      ]],
    })
  end)
end)

describe("single string replacement", function()
  it("replaces the input with the string", function()
    alternative.setup({
      rules = {
        custom = {
          hello_world = {
            input = { type = "string", pattern = "hello", lookahead = true },
            replacement = "world",
          },
        },
      },
    })

    helper.assert_scenario({
      input = [[
        local fo|o = "hello"
      ]],
      filetype = "lua",
      action = function()
        alternative.alternate("forward")
      end,
      expected = [[
        local foo = "world"
      ]],
    })
  end)
end)

describe("multiple strings replacement", function()
  describe("given the preview is false", function()
    it("replaces the input with the first string", function()
      alternative.setup({
        rules = {
          custom = {
            hello_world = {
              input = { type = "string", pattern = "hello", lookahead = true },
              replacement = { "universe", "world" },
              preview = false,
            },
          },
        },
      })

      helper.assert_scenario({
        input = [[
          local fo|o = "hello"
        ]],
        filetype = "lua",
        action = function()
          alternative.alternate("forward")
        end,
        expected = [[
          local foo = "universe"
        ]],
      })
    end)
  end)

  describe("given the preview is true", function()
    it("cycles through choices in both directions with alternate function", function()
      alternative.setup({
        rules = {
          custom = {
            hello_world = {
              input = { type = "string", pattern = "hello", lookahead = true },
              replacement = { "universe", "world", "continent" },
              preview = true,
            },
          },
        },
      })

      helper.assert_scenario({
        input = [[
          local fo|o = "hello"
        ]],
        filetype = "lua",
        action = function()
          -- Enter preview
          alternative.alternate("forward")
          helper.wait(10)
          -- To "world"
          alternative.alternate("forward")
          helper.wait(10)
          -- To "continent"
          alternative.alternate("forward")
          helper.wait(10)
          -- Back to "world"
          alternative.alternate("backward")
          helper.wait(10)

          -- Commit the preview
          vim.api.nvim_input("l")
          helper.wait(10)
        end,
        expected = [[
          local foo = "world"
        ]],
      })
    end)
  end)
end)

describe("function replacement", function()
  it("replaces the input with the result of the function", function()
    alternative.setup({
      rules = {
        custom = {
          single_string = {
            input = { type = "string", pattern = "hello", lookahead = true },
            replacement = function()
              return "world"
            end,
          },
          multiple_strings = {
            input = { type = "string", pattern = "goodbye", lookahead = true },
            replacement = function()
              return { "universe", "world" }
            end,
          },
        },
      },
    })

    helper.assert_scenario({
      input = [[
        local fo|o = "hello"
      ]],
      filetype = "lua",
      action = function()
        alternative.alternate("forward")
      end,
      expected = [[
        local foo = "world"
      ]],
    })

    helper.assert_scenario({
      input = [[
        local fo|o = "goodbye"
      ]],
      filetype = "lua",
      action = function()
        alternative.alternate("forward")
      end,
      expected = [[
        local foo = "universe"
      ]],
    })
  end)
end)

describe("preview", function()
  describe("given the preview is true", function()
    it("displays the preview as virtual text", function()
      alternative.setup({
        rules = { ["general.boolean_flip"] = { preview = true } },
      })

      helper.assert_scenario({
        input = "local fo|o = true",
        filetype = "lua",
        action = function()
          alternative.alternate("forward")
        end,
        expected = function()
          -- We are testing the internal implementation, not ideal
          local extmark = vim.api.nvim_buf_get_extmarks(0, preview.preview_ns, 0, -1, { details = true })[1]
          local preview_text = extmark[4].virt_text[1][1]
          assert.are.equal("false", preview_text)
        end,
      })
    end)

    describe("auto commit preview", function()
      it("commits the preview when the cursor moves", function()
        alternative.setup({
          rules = { ["general.boolean_flip"] = { preview = true } },
        })

        helper.assert_scenario({
          input = "local fo|o = true",
          filetype = "lua",
          action = function()
            alternative.alternate("forward")
            helper.wait(10)
            vim.api.nvim_input("l")
            helper.wait(10)
          end,
          expected = [[
            local foo = false
          ]],
        })
      end)

      it("commits the preview when the enter insert mode", function()
        alternative.setup({
          rules = { ["general.boolean_flip"] = { preview = true } },
        })

        helper.assert_scenario({
          input = "local fo|o = true",
          filetype = "lua",
          action = function()
            alternative.alternate("forward")
            helper.wait(10)
            vim.cmd("startinsert")
            helper.wait(10)
          end,
          expected = [[
            local foo = false
          ]],
        })
      end)
    end)

    it("cancels the preview when users hit Esc key", function()
      alternative.setup({
        rules = { ["general.boolean_flip"] = { preview = true } },
      })

      helper.assert_scenario({
        input = "local fo|o = true",
        filetype = "lua",
        action = function()
          alternative.alternate("forward")
          helper.wait(10)
          vim.api.nvim_input("<Esc>")
          helper.wait(10)
        end,
        expected = [[
          local foo = true
        ]],
      })

      local extmarks = vim.api.nvim_buf_get_extmarks(0, preview.preview_ns, 0, -1, { details = true })
      assert.are.equal(0, #extmarks)
    end)
  end)
end)

describe("select", function()
  describe("given multiple rules match", function()
    it("prompts user to select the rule", function()
      alternative.setup({
        rules = { "general.boolean_flip", "general.number_increment_decrement" },
      })

      stub(vim.fn, "getcharstr")

      helper.assert_scenario({
        input = "local fo|o = true or 42",
        filetype = "lua",
        action = function()
          -- Select the first option
          -- TODO: update this test once we support custom labels
          ---@diagnostic disable-next-line: undefined-field
          vim.fn.getcharstr.returns("a")
          alternative.alternate("forward")
        end,
        expected = [[
          local foo = false or 42
        ]],
      })

      helper.assert_scenario({
        input = "local fo|o = true or 42",
        filetype = "lua",
        action = function()
          -- Select the second option
          -- TODO: update this test once we support custom labels
          ---@diagnostic disable-next-line: undefined-field
          vim.fn.getcharstr.returns("s")
          alternative.alternate("forward")
        end,
        expected = [[
          local foo = true or 43
        ]],
      })

      ---@diagnostic disable-next-line: undefined-field
      vim.fn.getcharstr:revert()
    end)

    it("cancels the preview when user hits any other keys", function()
      alternative.setup({
        rules = { "general.boolean_flip", "general.number_increment_decrement" },
      })

      stub(vim.fn, "getcharstr")

      helper.assert_scenario({
        input = "local fo|o = true or 42",
        filetype = "lua",
        action = function()
          -- Select the first option
          -- TODO: update this test once we support custom labels
          ---@diagnostic disable-next-line: undefined-field
          vim.fn.getcharstr.returns("1")
          alternative.alternate("forward")
        end,
        expected = [[
          local foo = true or 42
        ]],
      })

      local extmarks = vim.api.nvim_buf_get_extmarks(0, preview.preview_ns, 0, -1, { details = true })
      assert.are.equal(0, #extmarks)

      ---@diagnostic disable-next-line: undefined-field
      vim.fn.getcharstr:revert()
    end)
  end)
end)

describe("dot repeat", function()
  it("dot repeat preserves the direction", function()
    alternative.setup({
      rules = { "general.boolean_flip", "general.number_increment_decrement" },
    })

    helper.assert_scenario({
      input = [[
        local fo|o = true
        local num = 42
      ]],
      filetype = "lua",
      action = function()
        alternative.alternate("forward")
        vim.cmd("normal! j")
        vim.cmd("normal! .")
      end,
      expected = [[
        local foo = false
        local num = 43
      ]],
    })
  end)
end)
