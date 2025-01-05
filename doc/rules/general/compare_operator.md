# general.compare_operator

## Source Code

<details>
<summary><strong>Show</strong></summary>

```lua
local utils = require("alternative.utils")

local base = {
  {
    input = {
      type = "callback",
      value = function()
        return utils.search_word_bounded("<", true)
      end,
      lookahead = true,
    },
    replacement = ">",
    description = "Change < to >",
    example = {
      input = "a| < b",
      output = "a > b",
    },
  },
  {
    input = {
      type = "callback",
      value = function()
        return utils.search_word_bounded(">", true)
      end,
      lookahead = true,
    },
    replacement = "<",
    description = "Change > to <",
    example = {
      input = "a| > b",
      output = "a < b",
    },
  },
  {
    input = {
      type = "callback",
      value = function()
        return utils.search_word_bounded("<=", true)
      end,
      lookahead = true,
    },
    replacement = ">=",
    description = "Change <= to >=",
    example = {
      input = "a| <= b",
      output = "a >= b",
    },
  },
  {
    input = {
      type = "callback",
      value = function()
        return utils.search_word_bounded(">=", true)
      end,
      lookahead = true,
    },
    replacement = "<=",
    description = "Change >= to <=",
    example = {
      input = "a| >= b",
      output = "a <= b",
    },
  },
}

local lua = {
  {
    input = {
      type = "callback",
      value = function()
        return utils.search_word_bounded("==", true)
      end,
      lookahead = true,
    },
    replacement = "~=",
    filetype = "lua",
    description = "Change == to ~=",
    example = {
      input = "a| == b",
      output = "a ~= b",
    },
  },
  {
    input = {
      type = "callback",
      value = function()
        return utils.search_word_bounded("~=", true)
      end,
      lookahead = true,
    },
    replacement = "==",
    description = "Change ~= to ==",
    example = {
      input = "a| ~= b",
      output = "a == b",
    },
  },
}

local javascript = {
  {
    input = {
      type = "callback",
      value = function()
        return utils.search_word_bounded("==", true)
      end,
      lookahead = true,
    },
    replacement = "!=",
    filetype = { "javascript", "typescript", "javascriptreact", "typescriptreact" },
    description = "Change == to !=",
    example = {
      input = "a| == b",
      output = "a != b",
    },
  },
  {
    input = {
      type = "callback",
      value = function()
        return utils.search_word_bounded("!=", true)
      end,
      lookahead = true,
    },
    replacement = "==",
    filetype = { "javascript", "typescript", "javascriptreact", "typescriptreact" },
    description = "Change != to ==",
    example = {
      input = "a| != b",
      output = "a == b",
    },
  },
  {
    input = {
      type = "callback",
      value = function()
        return utils.search_word_bounded("===", true)
      end,
      lookahead = true,
    },
    replacement = "!==",
    filetype = { "javascript", "typescript", "javascriptreact", "typescriptreact" },
    description = "Change === to !==",
    example = {
      input = "a| === b",
      output = "a !== b",
    },
  },
  {
    input = {
      type = "callback",
      value = function()
        return utils.search_word_bounded("!==", true)
      end,
      lookahead = true,
    },
    replacement = "===",
    filetype = { "javascript", "typescript", "javascriptreact", "typescriptreact" },
    description = "Change !== to ===",
    example = {
      input = "a| !== b",
      output = "a === b",
    },
  },
}

return vim.iter({ base, lua, javascript }):flatten():totable()
```

</details>

## Examples

### Change < to >

- Input:

```lua
a| < b
```

- Output:

```lua
a > b
```

### Change > to <

- Input:

```lua
a| > b
```

- Output:

```lua
a < b
```

### Change <= to >=

- Input:

```lua
a| <= b
```

- Output:

```lua
a >= b
```

### Change >= to <=

- Input:

```lua
a| >= b
```

- Output:

```lua
a <= b
```

### Change == to ~=

- Input:

```lua
a| == b
```

- Output:

```lua
a ~= b
```

### Change ~= to ==

- Input:

```lua
a| ~= b
```

- Output:

```lua
a == b
```

### Change == to !=

- Input:

```lua
a| == b
```

- Output:

```lua
a != b
```

### Change != to ==

- Input:

```lua
a| != b
```

- Output:

```lua
a == b
```

### Change === to !==

- Input:

```lua
a| === b
```

- Output:

```lua
a !== b
```

### Change !== to ===

- Input:

```lua
a| !== b
```

- Output:

```lua
a === b
```