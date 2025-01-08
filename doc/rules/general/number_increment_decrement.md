# general.number_increment_decrement

## Source Code

<details>
<summary><strong>Show</strong></summary>

```lua
local utils = require("alternative.utils")

return {
  input = {
    type = "callback",
    pattern = utils.search_number,
  },
  replacement = function(ctx)
    local add = ctx.direction == "forward" and 1 or -1
    local replacement = tostring(tonumber(ctx.current_text[1]) + add)
    return replacement
  end,
  description = "Increment or decrement the number",
  example = {
    input = "a| + 1",
    output = "a + 2",
  },
}
```

</details>

## Examples

> [!NOTE]
> `|` denotes the cursor position.

### Increment or decrement the number



- Input:

```lua
a| + 1
```

- Output:

```lua
a + 2
```