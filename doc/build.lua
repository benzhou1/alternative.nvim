-- Command: nvim -u doc/build.lua -c "quit"

local function get_rule_files(dir)
  local files = {}
  local p = io.popen('find "' .. dir .. '" -type f -name "*.lua"')

  if not p then
    error("Failed to run find command")
  end

  for file in p:lines() do
    table.insert(files, file)
  end

  p:close()
  return files
end

local function get_rule_name(rule_path)
  -- Remove lua/alternative/rules/ prefix and .lua suffix
  local name = rule_path:gsub("^lua/alternative/rules/", ""):gsub("%.lua$", "")
  -- Convert path separators to dots
  return name:gsub("/", ".")
end

local function ensure_dir_exists(file_path)
  local dir = file_path:match("(.*)/[^/]*$")
  os.execute('mkdir -p "' .. dir .. '"')
end

local function read_file(path)
  local file = io.open(path, "r")
  if not file then
    return nil
  end
  local content = file:read("*all")
  file:close()

  content = content:gsub("%s+$", "")
  return content
end

---@param rule Alternative.Rule
local function get_rule_note(rule)
  if not rule.note then
    return ""
  end

  local template = require("alternative.utils").format_indentation([[
    > [!NOTE]
    > %s
  ]])

  return string.format(template, rule.note)
end

---@param rule Alternative.Rule
local function rule_example(rule)
  local filetypes = rule.filetype
  local filetype

  if filetypes then
    filetype = type(filetypes) == "table" and filetypes[1] or filetypes
  end

  local template = require("alternative.utils").format_indentation([[
    ### %s

    %s

    - Input:

    ```%s
    %s
    ```

    - Output:

    ```%s
    %s
    ```
  ]])

  return string.format(
    template,
    rule.description,
    get_rule_note(rule),
    filetype,
    rule.example.input,
    filetype,
    rule.example.output
  )
end

local function generate_markdown_content(rule_path)
  local rules = require(rule_path:gsub("%.lua$", ""))

  local rule_body = {}

  -- Check if it's a group of rules
  if rules[1] then
    for _, rule in ipairs(rules) do
      table.insert(rule_body, rule_example(rule))
    end
  else
    table.insert(rule_body, rule_example(rules))
  end

  local template = require("alternative.utils").format_indentation([[
    # %s

    ## Source Code

    <details>
    <summary><strong>Show</strong></summary>

    ```lua
    %s
    ```

    </details>

    ## Examples

    > [!NOTE]
    > `|` denotes the cursor position.

    %s
  ]])

  return string.format(template, get_rule_name(rule_path), read_file(rule_path), table.concat(rule_body, "\n\n"))
end

local function generate_docs()
  local rules_dir = "lua/alternative/rules"
  local docs_dir = "doc/rules"

  -- Add rules directory to package.path so we can require rules
  package.path = package.path .. string.format(";%s/?.lua", rules_dir)
  package.path = package.path .. string.format(";lua/?.lua")

  for _, rule_file in ipairs(get_rule_files(rules_dir)) do
    local rule_name = get_rule_name(rule_file)
    local doc_path = docs_dir .. "/" .. rule_name:gsub("%.", "/") .. ".md"

    ensure_dir_exists(doc_path)
    local content = generate_markdown_content(rule_file)

    local file = io.open(doc_path, "w")
    if not file then
      error(string.format("Failed to write documentation for %s", rule_name))
    end

    file:write(content)
    file:close()
    print(string.format("Generated documentation for %s", rule_name))
  end
end

generate_docs()
