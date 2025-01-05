local config_mod = require("alternative.config")
local treesitter = require("alternative.treesitter")
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

---@class Alternative.Input
---@field text string[]
---@field range integer[]
---@field ts_captures table<string, TSNode[]>?
---@field indent integer

---@class Alternative.Rule
---@field input Alternative.Rule.Input How to get the input range
---@field trigger? fun(input: string): boolean Whether to trigger the replacement
---@field replacement string | string[] | fun(ctx: Alternative.Rule.ReplacementContext): string | string[] A string or a callback to resolve the string to replace
---@field preview? boolean Whether to show a preview of the replacement. Default: false
---@field description? string Description of the rule. This is used to generate the documentation.
---@field example? {input: string, output: string} An example input and output. This is used to generate the documentation.

---@class Alternative.Preview
---@field text string[] The preview text
---@field undo fun()

---@class Alternative.Module
---@field input Alternative.Input?
---@field current_rule {rule: Alternative.Rule, multi_choice_index: integer?}?
---@field preview Alternative.Preview?
---@field preview_events_cancel fun()?
local M = {
  input = nil,
  current_rule = nil,
  preview = nil,
  preview_events_cancel = nil,
}

---@param replacement string[]
---@param input Alternative.Input
function M._apply_preview(replacement, input)
  if M.preview then
    -- Undo previous preview if needed
    M.preview.undo()
  end

  local pre_conceallevel = vim.opt.conceallevel
  local pre_concealcursor = vim.opt.concealcursor
  vim.opt.conceallevel = 2
  vim.opt.concealcursor = "n"

  local virt_text = { { replacement[1], "Comment" } }
  local virt_lines
  if #replacement > 1 then
    virt_lines = vim
      .iter(replacement)
      :skip(1)
      :map(function(text)
        return { { text, "Comment" } }
      end)
      :totable()
  end

  local range = input.range
  local extmark_id = vim.api.nvim_buf_set_extmark(0, M.preview_ns, range[1], range[2], {
    end_row = range[3],
    end_col = range[4],
    conceal = "",
    virt_text = virt_text,
    virt_lines = virt_lines,
    virt_text_pos = "inline",
  })

  M.preview = {
    text = replacement,
    range = range,
    undo = function()
      vim.opt.conceallevel = pre_conceallevel
      vim.opt.concealcursor = pre_concealcursor
      vim.api.nvim_buf_del_extmark(0, M.preview_ns, extmark_id)
    end,
  }
end

function M._reset()
  M.input = nil
  M.current_rule = nil

  if M.preview then
    M.preview.undo()
    M.preview = nil
  end

  if M.preview_events_cancel then
    M.preview_events_cancel()
    M.preview_events_cancel = nil
  end
end

function M._commit_preview_change()
  if M.preview and M.input then
    local range = M.input.range
    vim.api.nvim_buf_set_text(0, range[1], range[2], range[3], range[4], M.preview.text)

    M._reset()
  end
end

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

  for _, rule_id in ipairs(config_mod.config.rules) do
    local content = require("alternative.rules." .. rule_id)

    -- A group of rules
    if content[1] then
      for _, rule in ipairs(content) do
        rule.__id__ = rule_id
        table.insert(_all, rule)
      end
    else
      content.__id__ = rule_id
      table.insert(_all, content)
    end
  end

  return _all
end

function M._setup_preview_events()
  if M.preview_events_cancel then
    return
  end

  vim.api.nvim_create_autocmd("CursorMoved", {
    group = M.preview_events_autocmd_group,
    callback = M._commit_preview_change,
    once = true,
  })

  M.preview_events_cancel = function()
    vim.on_key(nil, M.preview_events_ns)
    vim.api.nvim_clear_autocmds({
      group = M.preview_events_autocmd_group,
      event = "CursorMoved",
    })
  end

  vim.on_key(function(_, typed)
    if vim.fn.keytrans(typed) == "<Esc>" then
      M._reset()
    end
  end, M.preview_events_ns)
end

---@param direction "forward" | "backward"
function M._cycle_alternative(direction)
  -- Ignore if not if the rule doesn't have a multi choice
  if not M.current_rule.multi_choice_index then
    return
  end

  ---@type Alternative.Rule
  local current_rule = M.current_rule.rule
  local replacement, multi_choice_index = M._resolve_replacement(current_rule.replacement, M.input, direction)

  if replacement then
    M._apply_preview(replacement, M.input)
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

local function _show_rule_options(rules_by_row)
  local options = {}

  -- If there are multiple items on the same row and same column, display them
  -- in separate lines
  for row, items in pairs(rules_by_row) do
    table.sort(items, function(a, b)
      return a.col < b.col
    end)

    local function _make_line(_items)
      local seen = {}
      local duplicate = {}
      local line = ""

      for _, item in ipairs(_items) do
        if not seen[item.col] then
          table.insert(options, { label = item.label, entry = item.entry })
          line = line .. string.rep(" ", (item.col - #line)) .. item.label

          seen[item.col] = true
        else
          table.insert(duplicate, item)
        end
      end

      return line, duplicate
    end

    local _items = items
    local lines = {}
    while #_items > 0 do
      local line, duplicate = _make_line(_items)
      table.insert(lines, line)
      _items = duplicate
    end

    local virt_lines = vim
      .iter(lines)
      :map(function(line)
        return { { line, "CursorLineNr" } }
      end)
      :totable()

    vim.api.nvim_buf_set_extmark(0, M.rule_selection_ns, row, 0, {
      virt_lines = virt_lines,
    })
  end

  local current_row = vim.fn.line(".") - 1
  vim.api.nvim_buf_set_extmark(0, M.rule_selection_ns, current_row, 0, {
    virt_text = { { string.rep(" ", 4) .. "? to show rule name", "Comment" } },
    virt_text_pos = "eol",
  })

  return options
end

local function _show_rule_options_verbose(rules_by_row)
  local options = {}

  for row, items in pairs(rules_by_row) do
    local virt_lines = vim
      .iter(items)
      :map(function(item)
        table.insert(options, { label = item.label, entry = item.entry })

        local split = vim.split(item.entry.rule.__id__, ".", { plain = true })
        local short_id = split[#split]
        return {
          { string.rep(" ", item.col) },
          { item.label, "CursorLineNr" },
          { string.format(" (%s)", short_id), "Comment" },
        }
      end)
      :totable()

    vim.api.nvim_buf_set_extmark(0, M.rule_selection_ns, row, 0, {
      virt_lines = virt_lines,
    })
  end

  return options
end

---@param entries {rule: Alternative.Rule, input: Alternative.Input}[]
---@param show_rule_id boolean Whether to show the rule id
---@param callback fun(entry: {rule: Alternative.Rule, input: Alternative.Input}) Callback to be called after the user selects a rule
function M._select_rule(entries, show_rule_id, callback)
  local option_labels = { "a", "s", "d", "f", "g", "h", "j", "k", "l", ";" }
  local by_row = vim.defaulttable(function()
    return {}
  end)

  for i, entry in ipairs(entries) do
    local input = entry.input

    local srow = input.range[1]
    local scol = input.range[2]
    vim.api.nvim_buf_set_extmark(0, M.rule_selection_ns, srow, scol, {
      hl_group = "Alternative.RuleSelectionBackdrop",
      end_row = input.range[3],
      end_col = input.range[4],
    })

    table.insert(by_row[srow], { col = scol, entry = entry, label = option_labels[i] })
  end

  local options = show_rule_id and _show_rule_options_verbose(by_row) or _show_rule_options(by_row)

  -- Setup keyboard input handlers
  -- We need to redraw first, otherwise, getcharstr will block the UI
  vim.cmd("redraw")
  local ok, ret = pcall(vim.fn.getcharstr)
  if ok then
    local char = vim.fn.keytrans(ret)

    local selected = vim.iter(options):find(function(option)
      return option.label == char
    end)

    if selected then
      callback(selected.entry)
      vim.api.nvim_buf_clear_namespace(0, M.rule_selection_ns, 0, -1)
    elseif char == "?" and not show_rule_id then
      vim.api.nvim_buf_clear_namespace(0, M.rule_selection_ns, 0, -1)
      M._select_rule(entries, true, callback)
    else
      -- Any other keys would cancel the selection
      vim.api.nvim_buf_clear_namespace(0, M.rule_selection_ns, 0, -1)
    end
  end
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
      M._apply_preview(replacement, input)
      M.current_rule = { rule = rule, multi_choice_index = multi_choice_index }

      -- Save the input so we don't have to compute it again when cycling through alternatives
      M.input = input

      vim.schedule(M._setup_preview_events)
    else
      vim.api.nvim_buf_set_text(0, input.range[1], input.range[2], input.range[3], input.range[4], replacement)
    end
  end

  -- If we are in preview mode, cycle through the choices
  if M.current_rule and M.preview then
    return M._cycle_alternative(direction)
  end

  local eligible_rules = M._eligible_rules()
  if #eligible_rules > 1 then
    M._select_rule(eligible_rules, false, apply_rule)
  elseif #eligible_rules == 1 then
    apply_rule(eligible_rules[1])
  end
end

M.setup = function(config)
  config_mod.setup(config)
  treesitter.setup()

  M.preview_ns = vim.api.nvim_create_namespace("alternative.preview")
  M.preview_events_ns = vim.api.nvim_create_namespace("alternative.preview_events")
  M.preview_events_autocmd_group = vim.api.nvim_create_augroup("alternative.preview_events", { clear = true })

  M.rule_selection_ns = vim.api.nvim_create_namespace("alternative.rule_selection")
  M.rule_selection_events_ns = vim.api.nvim_create_namespace("alternative.rule_selection_events")

  M.rules = M._all_rules()

  vim.api.nvim_set_hl(0, "Alternative.RuleSelectionBackdrop", { link = "Comment" })

  local events = { "InsertEnter", "BufLeave", "WinLeave", "CmdlineEnter" }
  for _, event in ipairs(events) do
    vim.api.nvim_create_autocmd(event, {
      group = M.preview_events_autocmd_group,
      callback = M._commit_preview_change,
    })
  end
end

return M
