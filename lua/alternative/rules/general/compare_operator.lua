local utils = require("alternative.utils")

local base = {
  {
    input = {
      type = "callback",
      value = function()
        return utils.search_word_bounded("<", true)
      end,
    },
    replacement = ">",
  },
  {
    input = {
      type = "callback",
      value = function()
        return utils.search_word_bounded(">", true)
      end,
    },
    replacement = "<",
    lookahead = true,
  },
  {
    input = {
      type = "callback",
      value = function()
        return utils.search_word_bounded("<=", true)
      end,
    },
    replacement = ">=",
    lookahead = true,
  },
  {
    input = {
      type = "callback",
      value = function()
        return utils.search_word_bounded(">=", true)
      end,
    },
    replacement = "<=",
    lookahead = true,
  },
}

local lua = {
  {
    input = {
      type = "callback",
      value = function()
        return utils.search_word_bounded("==", true)
      end,
    },
    replacement = "~=",
    lookahead = true,
    filetype = "lua",
  },
  {
    input = {
      type = "callback",
      value = function()
        return utils.search_word_bounded("~=", true)
      end,
    },
    replacement = "==",
    lookahead = true,
  },
}

local javascript = {
  {
    input = {
      type = "callback",
      value = function()
        return utils.search_word_bounded("==", true)
      end,
    },
    replacement = "!=",
    lookahead = true,
    filetype = { "javascript", "typescript", "javascriptreact", "typescriptreact" },
  },
  {
    input = {
      type = "callback",
      value = function()
        return utils.search_word_bounded("!=", true)
      end,
    },
    replacement = "==",
    lookahead = true,
    filetype = { "javascript", "typescript", "javascriptreact", "typescriptreact" },
  },
  {
    input = {
      type = "callback",
      value = function()
        return utils.search_word_bounded("===", true)
      end,
    },
    replacement = "!==",
    lookahead = true,
    filetype = { "javascript", "typescript", "javascriptreact", "typescriptreact" },
  },
  {
    input = {
      type = "callback",
      value = function()
        return utils.search_word_bounded("!==", true)
      end,
    },
    replacement = "===",
    lookahead = true,
    filetype = { "javascript", "typescript", "javascriptreact", "typescriptreact" },
  },
}

return vim.iter({ base, lua, javascript }):flatten():totable()
