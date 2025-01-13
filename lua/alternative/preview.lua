---@class Alternative.Preview
---@field text string[] The preview text
---@field undo fun()

---@class Alternative.Preview.Module
---@field input Alternative.Input?
---@field preview Alternative.Preview?
---@field preview_events_cancel fun()?
local M = {
  input = nil,
  preview = nil,
  preview_events_cancel = nil,
  reset_hook = nil,
}

---@param replacement string[]
---@param input Alternative.Input
function M.apply(replacement, input)
  if M.preview then
    -- Undo previous preview if needed
    M.preview.undo()
  end

  M.input = input

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

function M.reset()
  M.input = nil

  if M.preview then
    M.preview.undo()
    M.preview = nil
  end

  if M.preview_events_cancel then
    M.preview_events_cancel()
    M.preview_events_cancel = nil
  end

  if M.reset_hook then
    M.reset_hook()
  end
end

function M.commit()
  if M.preview and M.input then
    local range = M.input.range
    vim.api.nvim_buf_set_text(0, range[1], range[2], range[3], range[4], M.preview.text)

    M.reset()
  end
end

function M.is_previewing()
  return M.preview ~= nil
end

function M.previewing_text()
  return M.is_previewing() and M.preview.text or nil
end

function M.previewing_input()
  return M.input
end

function M.setup_cancel_events()
  if M.preview_events_cancel then
    return
  end

  vim.api.nvim_create_autocmd("CursorMoved", {
    group = M.preview_events_autocmd_group,
    callback = M.commit,
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
      M.reset()
    end
  end, M.preview_events_ns)
end

function M.on_reset(callback)
  M.reset_hook = callback
end

function M.setup()
  M.preview_ns = vim.api.nvim_create_namespace("alternative.preview")
  M.preview_events_ns = vim.api.nvim_create_namespace("alternative.preview_events")
  M.preview_events_autocmd_group = vim.api.nvim_create_augroup("alternative.preview_events", { clear = true })

  local events = { "InsertEnter", "BufLeave", "WinLeave", "CmdlineEnter" }
  for _, event in ipairs(events) do
    vim.api.nvim_create_autocmd(event, {
      group = M.preview_events_autocmd_group,
      callback = M.commit,
    })
  end
end

return M
