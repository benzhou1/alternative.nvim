local config_mod = require("alternative.config")
local treesitter = require("alternative.treesitter")
local preview = require("alternative.preview")
local select = require("alternative.select")
local utils = require("alternative.utils")

---@class Alternative.Rule.ReplacementContext
---@field original_text string[]
---@field current_text string[] The current visible text. If a preview is showing, it's the preview text. Otherwise, it's the original_text
---@field direction "forward" | "backward" The cycle direction
---@field query_captures table<string, TSNode>? The Treesitter query captures

---@class Alternative.Rule.Input
---@field type "string" | "strings" | "query" | "callback"
---@field pattern string | string[] | fun(): integer[]
---@field lookahead? boolean Whether to look ahead from the current cursor position to find the input. Only applied for input with type "string", "strings", or "query". Default: false
---@field container? string A Treesitter node type to limit the input range. Only applies if type is "query". When this is specified, we first traverse up the tree from the current node to find the container, then execute the query within the container. Defaults to use the root as the container.

---@class Alternative.Rule
---@field input Alternative.Rule.Input How to get the input range
---@field trigger? fun(input: string): boolean Whether to trigger the replacement
---@field replacement string | string[] | fun(ctx: Alternative.Rule.ReplacementContext): string | string[] A string or a callback to resolve the string to replace
---@field preview? boolean Whether to show a preview of the replacement. Default: false
---@field description? string Description of the rule. This is used to generate the documentation.
---@field example? {input: string, output: string} An example input and output. This is used to generate the documentation.

---@class Alternative.Module
---@field current_rule {rule: Alternative.Rule, multi_choice_index: integer?}?
local M = {
  current_rule = nil,
}

---The input can be either:
---1. A string: the current word should be equal to the input
---2. A list of strings: the current word should be in the list
---3. A callback: the callback should return the range of the input text
---@param input Alternative.Rule.Input
---@return Alternative.Input?
function M._resolve_input(input)
  local pattern = input.pattern
  local indent = vim.fn.indent(vim.fn.line("."))
  local lookahead = input.lookahead or false

  if input.type == "string" then
    ---@cast pattern string
    local range = utils.search_word(pattern, lookahead)
    if not range then
      return nil
    end

    local current_word = vim.api.nvim_buf_get_text(0, range[1], range[2], range[3], range[4], {})
    return { text = current_word, range = range, indent = indent }
  elseif input.type == "strings" then
    ---@cast pattern string[]
    local range = utils.search_words(pattern, lookahead)
    if not range then
      return nil
    end

    local current_word = vim.api.nvim_buf_get_text(0, range[1], range[2], range[3], range[4], {})
    return { text = current_word, range = range, indent = indent }
  elseif input.type == "callback" then
    local range = pattern()
    if range then
      local input_text = vim.api.nvim_buf_get_text(0, range[1], range[2], range[3], range[4], {})
      return { text = input_text, range = range, indent = indent }
    else
      return nil
    end
  elseif input.type == "query" then
    ---@cast pattern string
    local ts_captures, range = treesitter.query(pattern, lookahead, input.container)
    if not range then
      return nil
    end

    local input_text = vim.api.nvim_buf_get_text(0, range[1], range[2], range[3], range[4], {})
    return { text = input_text, range = range, ts_captures = ts_captures, indent = indent }
  end
end

---Expand the capture in the replacement string. For example, given the string "not (@__input__)", it will replace @__input__ with the content of the captured node
---@param text string
---@return string[]
function M._expand_replacement_capture(text, captures)
  local replaced = text:gsub("@([%w%d_-]+)", function(match)
    local nodes = captures[match]
    if not nodes then
      error(string.format("Capture @%s is not found", match))
    end

    return vim.treesitter.get_node_text(nodes[1], 0)
  end)

  return vim.split(replaced, "\n", { plain = true })
end

---@param replacement string | string[] | function
---@param input Alternative.Input
---@param direction "forward" | "backward"
---@return string[]? replacement, integer? multi_choice_index
function M._resolve_replacement(replacement, input, direction)
  local current_text = M.preview and M.preview.text or input.text

  -- Expand the replacement if it's a function
  if type(replacement) == "function" then
    ---@type Alternative.Rule.ReplacementContext
    local context = {
      original_text = input.text,
      current_text = current_text,
      direction = direction,
      query_captures = input.ts_captures,
    }

    replacement = replacement(context)
  end

  local to_replace
  local multi_choice_index = nil

  if type(replacement) == "string" then
    to_replace = { replacement }
  elseif type(replacement) == "table" then
    ---@type integer?
    local current_index = M.current_rule and M.current_rule.multi_choice_index or nil
    if current_index == nil then
      current_index = direction == "forward" and 1 or #replacement
    else
      current_index = direction == "forward" and current_index + 1 or current_index - 1
    end

    -- Guard out of bounds
    if current_index < 1 or current_index > #replacement then
      current_index = nil
    end

    to_replace = current_index and { replacement[current_index] } or nil
    multi_choice_index = current_index
  end

  if input.ts_captures and to_replace then
    to_replace = M._expand_replacement_capture(to_replace[1], input.ts_captures)
  end

  -- Indent from second line
  if input.indent > 0 and to_replace and #to_replace > 1 then
    for i = 2, #to_replace do
      to_replace[i] = string.rep(" ", input.indent) .. to_replace[i]
    end
  end

  return to_replace, multi_choice_index
end

function M._all_rules()
  local _all = {}

  local function handle_rule(rule_content, rule_id)
    -- A group of rules
    if rule_content[1] then
      for _, rule in ipairs(rule_content) do
        rule.__id__ = rule_id
        table.insert(_all, rule)
      end
    else
      rule_content.__id__ = rule_id
      table.insert(_all, rule_content)
    end
  end

  -- Custom rules
  local custom_rules = config_mod.config.rules.custom or {}
  for rule_id, rule in pairs(custom_rules) do
    handle_rule(rule, "custom." .. rule_id)
  end

  -- Built-in rules
  for _, rule_id in ipairs(config_mod.config.rules) do
    local content = require("alternative.rules." .. rule_id)
    handle_rule(content, rule_id)
  end

  return _all
end

function M._setup_preview_events() end

---@param direction "forward" | "backward"
function M._cycle_alternative(direction)
  -- Ignore if not if the rule doesn't have a multi choice
  if not M.current_rule.multi_choice_index then
    return
  end

  ---@type Alternative.Rule
  local current_rule = M.current_rule.rule
  local replacement, multi_choice_index =
    M._resolve_replacement(current_rule.replacement, preview.previewing_input(), direction)

  if replacement then
    preview.apply(replacement, preview.previewing_input())
    M.current_rule.multi_choice_index = multi_choice_index
  end
end

---@return {rule: Alternative.Rule, input: Alternative.Input}[] rules A list of rules that can be applied, sorted by input range
function M._eligible_rules()
  local result = {}

  for _, rule in ipairs(M.rules) do
    if rule.filetype then
      local filetypes = type(rule.filetype) == "table" and rule.filetype or { rule.filetype }
      if not vim.tbl_contains(filetypes, vim.bo.filetype) then
        goto continue
      end
    end

    local input = M._resolve_input(rule.input)

    if input == nil then
      goto continue
    end

    if rule.trigger and not rule.trigger(input.text) then
      goto continue
    end

    table.insert(result, { rule = rule, input = input })
    ::continue::
  end

  table.sort(result, function(a, b)
    return utils.compare_array(
      { a.input.range[1], a.input.range[2], a.rule.__id__ },
      { b.input.range[1], b.input.range[2], b.rule.__id__ }
    ) == -1
  end)

  return result
end

---@param direction "forward" | "backward"
function M.alternate(direction)
  local function apply_rule(entry)
    local rule = entry.rule
    local input = entry.input

    local replacement, multi_choice_index = M._resolve_replacement(rule.replacement, input, direction)
    assert(replacement, "Can not resolve replacement")

    vim.api.nvim_win_set_cursor(0, { input.range[1] + 1, input.range[2] })
    if rule.preview then
      preview.apply(replacement, input)
      M.current_rule = { rule = rule, multi_choice_index = multi_choice_index }
      vim.schedule(preview.setup_cancel_events)
    else
      vim.api.nvim_buf_set_text(0, input.range[1], input.range[2], input.range[3], input.range[4], replacement)
    end
  end

  -- If we are in preview mode, cycle through the choices
  if M.current_rule and preview.is_previewing() then
    return M._cycle_alternative(direction)
  end

  local eligible_rules = M._eligible_rules()
  if #eligible_rules > 1 then
    select.show(eligible_rules, false, apply_rule)
  elseif #eligible_rules == 1 then
    apply_rule(eligible_rules[1])
  end
end

M.setup = function(config)
  config_mod.setup(config)
  treesitter.setup()

  preview.setup()
  preview.on_reset(function()
    M.current_rule = nil
  end)

  select.setup()

  M.rules = M._all_rules()

  vim.api.nvim_set_hl(0, "Alternative.RuleSelectionBackdrop", { link = "Comment" })
end

return M
