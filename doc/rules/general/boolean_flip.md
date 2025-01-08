# general.boolean_flip

## Source Code

<details>
<summary><strong>Show</strong></summary>

```lua
return {
  input = {
    type = "strings",
    pattern = { "true", "false" },
    lookahead = true,
  },
  replacement = function(ctx)
    local mapping = {
      ["true"] = "false",
      ["false"] = "true",
    }

    return mapping[ctx.original_text[1]]
  end,
  description = "Change true to false and vice versa",
  example = {
    input = "local fla|g = true",
    output = "local flag = false",
  },
}
```

</details>

## Examples

> [!NOTE]
> `|` denotes the cursor position.

### Change true to false and vice versa



- Input:

```nil
local fla|g = true
```

- Output:

```nil
local flag = false
```