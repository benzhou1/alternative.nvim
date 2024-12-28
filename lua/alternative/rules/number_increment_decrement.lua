local utils = require("alternative.utils")

return {
  input = {
    type = "callback",
    value = utils.search_number,
  },
  replacement = function(ctx)
    local add = ctx.direction == "forward" and 1 or -1
    local replacement = tostring(tonumber(ctx.current_text[1]) + add)
    return replacement
  end,
}
