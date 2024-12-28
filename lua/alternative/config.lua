local M = {}

local default_config = {
  rules = {},
}

function M.setup(config)
  local user_config = config or {}

  M.config = vim.tbl_deep_extend("force", default_config, user_config)
end

return M
