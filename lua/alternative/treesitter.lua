local M = {}

local function compare_points_before(a, b)
  if a[1] == b[1] then
    return a[2] <= b[2]
  else
    return a[1] < b[1]
  end
end

local function cursor_before_node(ts_node)
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  cursor_pos = { cursor_pos[1] - 1, cursor_pos[2] }

  local start_row, start_col, _, _ = ts_node:range()
  return compare_points_before(cursor_pos, { start_row, start_col })
end

local function cursor_inside_node(ts_node)
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  cursor_pos = { cursor_pos[1] - 1, cursor_pos[2] }

  local start_row, start_col, end_row, end_col = ts_node:range()
  return compare_points_before({ start_row, start_col }, cursor_pos)
    and compare_points_before(cursor_pos, { end_row, end_col })
end

---@return boolean
local function filter_by_cursor(captures, lookahead)
  local input_capture = captures["input"][1]

  -- If lookahead is false, the cursor must be inside the @input capture
  -- If lookahead is true, the cursor can be before the @input
  return lookahead and cursor_before_node(input_capture) or cursor_inside_node(input_capture)
end

local function find_closest_ancestor(node_type)
  local node = vim.treesitter.get_node({ bufnr = 0 })
  if not node then
    return nil
  end

  while node do
    if node:type() == node_type then
      return node
    end
    node = node:parent()
  end

  return nil
end

---@param query_string string
---@param lookahead boolean The result node must contain the cursor. If lookahead is false, the cursor must be inside the @input capture. If lookahead is true, the cursor can be before the @input
---@param container string?
---@return table<string, TSNode>? captures, integer[]? range
function M.query(query_string, lookahead, container)
  local bufnr = vim.api.nvim_get_current_buf()
  local lang = vim.bo.filetype
  local query = vim.treesitter.query.parse(lang, query_string)

  local parser = vim.treesitter.get_parser(bufnr, lang)
  local tree = parser:parse()[1]

  local root_node
  if container then
    root_node = find_closest_ancestor(container)
  else
    root_node = tree:root()
  end

  if not root_node then
    return nil
  end

  for _, match in query:iter_matches(root_node, bufnr, 0, -1, { all = true }) do
    local captures = {}

    for id, nodes in pairs(match) do
      local name = query.captures[id]
      captures[name] = nodes
    end

    if filter_by_cursor(captures, lookahead) then
      local start_row, start_col, end_row, end_col = captures.input[1]:range()
      local range = { start_row, start_col, end_row, end_col }
      return captures, range
    end
  end
end

function M.setup()
  vim.treesitter.query.add_predicate("type?", function(match, _, _, predicate)
    local node = match[predicate[2]]
    local type = predicate[3]

    return node:type() == type
  end, { force = true })
end

return M
