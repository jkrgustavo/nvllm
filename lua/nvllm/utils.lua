local M = {}

function M.get_visual_selection()
    local _, srow, scol = unpack(vim.fn.getpos('v'))
    local _, erow, ecol = unpack(vim.fn.getpos('.'))
    local ret = {}

    if vim.fn.mode() == 'V' then
        if srow > erow then
            ret = vim.api.nvim_buf_get_lines(0, erow - 1, srow, true)
        else
            ret = vim.api.nvim_buf_get_lines(0, srow - 1, erow, true)
        end
    end

    if vim.fn.mode() == 'v' then
    if srow < erow or (srow == erow and scol <= ecol) then
        ret = vim.api.nvim_buf_get_text(0, srow - 1, scol - 1, erow - 1, ecol, {})
    else
        ret = vim.api.nvim_buf_get_text(0, erow - 1, ecol - 1, srow - 1, scol, {})
    end
end

if vim.fn.mode() == '\22' then
    local lines = {}
    if srow > erow then
        srow, erow = erow, srow
    end
    if scol > ecol then
        scol, ecol = ecol, scol
    end
    for i = srow, erow do
        table.insert(lines, vim.api.nvim_buf_get_text(0, i - 1, math.min(scol - 1, ecol), i - 1, math.max(scol - 1, ecol), {})[1])
    end
    ret = lines
end
return ret
end

---@param t table
---@param indent_level number?
---@param printed_tables table?
function M.pretty_table_format(t, indent_level, printed_tables)
indent_level = indent_level or 0
printed_tables = printed_tables or {}

if type(t) ~= "table" then
    return tostring(t)
end

if printed_tables[t] then
    return "{ ... }" -- Avoid infinite recursion
    end
    printed_tables[t] = true

    local lines = {"{"}
    local indent = string.rep(" ", indent_level * 2)
    local inner_indent = string.rep(" ", (indent_level + 1) * 2)

    for k, v in pairs(t) do
        local key = type(k) == "string" and string.format('"%s"', k) or string.format("[%s]", tostring(k))
        local value
        if type(v) == "table" then
            value = M.pretty_table_format(v, indent_level + 1, printed_tables)
        else
            value = type(v) == "string" and string.format('"%s"', v) or tostring(v)
        end
        table.insert(lines, string.format("%s%s = %s,", inner_indent, key, value))
    end

    table.insert(lines, indent .. "}")
    return table.concat(lines, "\n")
end

---@param path string
---@return table|nil, string?
function M.read_file(path)
    local file, err = io.open(path, "rb")
    local env = {}

    if not file then
        return nil, err
    end

    for line in file:lines() do
        if line:match("^%s*[^#]") then
            line = line:match("^%s*(.-)%s*$")

            local key, value = line:match("^([^=]+)=(.*)$")
            if key and value then
                key = key:match("^%s*(.-)%s*$")
                value = value:match("^%s*(.-)%s*$")

                value = value:match('^"(.*)"$') or value:match("^'(.*)'$") or value

                env[key] = value
            end
        end
    end

    file:close()

    if env == {} then
        return nil
    end

    return env
end

return M
