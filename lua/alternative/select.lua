local M = {}

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
function M.show(entries, show_rule_id, callback)
  local config = require("alternative.config").config
  local option_labels = vim.split(config.select_labels, "", { plain = true })

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

  --- Defer to make sure Neovim has a change to redraw the screen
  --- The 50ms is chosen arbitrarily
  vim.defer_fn(function()
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
        M.show(entries, true, callback)
      else
        -- Any other keys would cancel the selection
        vim.api.nvim_buf_clear_namespace(0, M.rule_selection_ns, 0, -1)
      end
    end
  end, 50)
end

function M.setup()
  M.rule_selection_ns = vim.api.nvim_create_namespace("alternative.rule_selection")
  M.rule_selection_events_ns = vim.api.nvim_create_namespace("alternative.rule_selection_events")
end

return M
