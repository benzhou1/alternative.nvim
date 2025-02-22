local M = {}

---@param bounded_whitespaces boolean Whether to use whitespaces as word boundary
function M.get_current_word(bounded_whitespaces)
  local cursor = vim.api.nvim_win_get_cursor(0)
  -- Get the current word range using visual selection
  local command = bounded_whitespaces and "normal! viW" or "normal! viw"
  vim.cmd(command)
  local v_start = vim.fn.getpos("v")
  local v_end = vim.fn.getpos(".")
  -- Exit visual mode
  vim.cmd("normal! v")

  -- Preserve the current cursor position
  vim.api.nvim_win_set_cursor(0, cursor)

  -- Minus 1 because 0-indexed
  local range = { v_start[2] - 1, v_start[3] - 1, v_end[2] - 1, v_end[3] }
  local text = vim.api.nvim_buf_get_text(0, range[1], range[2], range[3], range[4], {})[1]
  return text, range
end

---Search the word in the current line
---1. First search in the current word. The current word range is same as the range if we visually select with viw
---2. If not found, look ahead from the cursor position
---@param word string
---@param lookahead boolean
---@return integer[]? range
function M.search_word(word, lookahead)
  local text, range = M.get_current_word(false)

  if text == word then
    return range
  end

  -- If not match, try to look ahead
  if lookahead then
    local cursor = vim.api.nvim_win_get_cursor(0)
    local line = vim.api.nvim_get_current_line()
    local start_idx, end_idx = line:find(word, cursor[2])
    if not start_idx or not end_idx then
      return nil
    end

    return { cursor[1] - 1, start_idx - 1, cursor[1] - 1, end_idx }
  else
    return nil
  end
end

---Similar to search_word, but search for multiple words
---@param words string[]
---@param lookahead boolean
---@return integer[]? range
function M.search_words(words, lookahead)
  local text, range = M.get_current_word(false)

  if vim.list_contains(words, text) then
    return range
  end

  -- If not match, try to look ahead
  if lookahead then
    local cursor = vim.api.nvim_win_get_cursor(0)
    local line = vim.api.nvim_get_current_line()

    for _, word in ipairs(words) do
      local start_idx, end_idx = line:find(word, cursor[2])
      if start_idx and end_idx then
        return { cursor[1] - 1, start_idx - 1, cursor[1] - 1, end_idx }
      end
    end
  end

  return nil
end

---Search the word (bounded by whitespaces) in the current line
function M.search_word_bounded(word, lookahead)
  local text, range = M.get_current_word(true)

  if text == word then
    return range
  end

  -- If not match, try to look ahead
  if lookahead then
    local cursor = vim.api.nvim_win_get_cursor(0)
    local line = vim.api.nvim_get_current_line()
    local patterns = {
      "^" .. word .. "%f[%s]", -- Start of line
      "%f[%S]" .. word .. "$", -- End of line
      "%f[%S]" .. word .. "%f[%s]", -- Middle of line
      "^" .. word .. "$", -- Exact match
    }

    local start_idx, end_idx
    for _, pattern in ipairs(patterns) do
      start_idx, end_idx = line:find(pattern, cursor[2])
      if start_idx and end_idx then
        break
      end
    end

    if not start_idx or not end_idx then
      return nil
    end

    return { cursor[1] - 1, start_idx - 1, cursor[1] - 1, end_idx }
  end

  return nil
end

---Lookahead from the current cursor position to find number. It can handles negative numbers.
---For example:
---local foo = -7|89
---will return -789
---@return integer[]? range
function M.search_number()
  local line = vim.api.nvim_get_current_line()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row = cursor[1]
  local col = cursor[2]

  -- Find the first non-digit character start the the cursor position
  local start_pos = 1
  for i = col + 1, 1, -1 do
    local char = line:sub(i, i)
    if not char:match("%d") then
      start_pos = i
      break
    end
  end

  local prefix = start_pos > 1 and line:sub(start_pos, start_pos) or nil

  if prefix == "-" then
    start_pos = start_pos - 1
  end

  local start_idx, end_idx = line:find("%-?%d+", start_pos + 1)

  if not start_idx or not end_idx then
    return nil
  end

  return { row - 1, start_idx - 1, row - 1, end_idx }
end

-- Stable pairs iterator, keys are sorted by alphabetical order
function M.stable_pairs(t)
  local keys = {}
  for k in pairs(t) do
    table.insert(keys, k)
  end

  table.sort(keys)

  local i = 0

  return function()
    i = i + 1
    if keys[i] then
      return keys[i], t[keys[i]]
    end
  end
end

---Trim the redundant whitespaces from the input lines while preserving the indentation level.
---@param input string
---@return string
function M.format_indentation(input)
  input = input:gsub("%s+$", "")
  local lines = vim.split(input, "\n", { trimempty = false })
  local smallest_indent

  for _, line in ipairs(lines) do
    -- Count the number of leading whitespaces
    -- Don't consider indent of empty lines
    local leading_whitespaces = line:match("^%s*")
    if #leading_whitespaces ~= line:len() then
      smallest_indent = smallest_indent and math.min(smallest_indent, #leading_whitespaces) or #leading_whitespaces
    end
  end

  for i, line in ipairs(lines) do
    line = line:sub(smallest_indent + 1)
    lines[i] = line
  end

  return table.concat(lines, "\n")
end

---Compare same dimension arrays
---@param arr1 integer[]
---@param arr2 integer[]
---@return integer 1 if arr1 > arr2, 0 if arr1 == arr2, -1 if arr1 < arr2
function M.compare_array(arr1, arr2)
  if #arr1 ~= #arr2 then
    error("Arrays have different dimensions")
  end

  for i = 1, #arr1 do
    if arr1[i] < arr2[i] then
      return -1
    elseif arr1[i] > arr2[i] then
      return 1
    end
  end

  return 0
end

---@param range integer[] 0-indexed
function M.cursor_in_range(range)
  local cursor = vim.api.nvim_win_get_cursor(0)
  -- Plus 1 because cursor position is 1-indexed
  local after_range_start = M.compare_array({ range[1] + 1, range[2] }, cursor)
  local before_range_end = M.compare_array({ range[3] + 1, range[4] }, cursor)
  return vim.list_contains({ -1, 0 }, after_range_start) and vim.list_contains({ 0, 1 }, before_range_end)
end

---@param ts_node TSNode
function M.cursor_in_node(ts_node)
  local srow, scol, erow, ecol = ts_node:range()
  return M.cursor_in_range({ srow, scol, erow, ecol })
end

return M
