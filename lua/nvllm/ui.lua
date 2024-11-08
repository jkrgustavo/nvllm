local Utils = require("nvllm.utils")
package.loaded["nvllm.utils"] = nil

---@class NvllmUi
---@field active_bufnr number
---@field namespace number
---@field config NvllmUiConfig
local NvllmUi = {}

NvllmUi.__index = NvllmUi

---@param config NvllmUiConfig
function NvllmUi:new(config)

    local instance = setmetatable({
        active_bufnr = nil,
        config = config
    }, self)
    instance:create_buffer()

    return instance
end

function NvllmUi:create_window()
    local opts = self.config
    local width = opts.dimensions.width
    local height = opts.dimensions.height

    local window = vim.api.nvim_open_win(self.active_bufnr, true, {
        relative = "editor",
        width = width,
        height = height,
        row = math.floor((vim.o.lines - height) / 2),
        col = math.floor((vim.o.columns - width) / 2),
        style = 'minimal',
        border = 'rounded',
        title = 'Stitch'
    })

    vim.api.nvim_create_autocmd({ "BufLeave", "BufWinLeave" }, {
        buffer = self.active_bufnr,
        once = true,
        callback = function()
            if vim.api.nvim_buf_is_valid(self.active_bufnr) then
                vim.api.nvim_win_close(0, true)
            end
        end
    })

    return window
end

function NvllmUi:create_buffer()
    if not self.active_bufnr or not vim.api.nvim_buf_is_valid(self.active_bufnr) then
        local active_bufnr = vim.api.nvim_create_buf(false, false)
        vim.api.nvim_set_option_value('buftype', 'nofile', { buf = active_bufnr })
        vim.api.nvim_set_option_value('bufhidden', 'hide', { buf = active_bufnr })
        vim.api.nvim_set_option_value('buflisted', false, { buf = active_bufnr })
        self.active_bufnr = active_bufnr
    end
end

function NvllmUi:open_window()
    local window = self:create_window()

    vim.api.nvim_win_set_buf(window, self.active_bufnr)
end

function NvllmUi:print(...)
    local arg = {...}
    local output = table.concat(arg, '\t') .. '\n'

    local lines = {}
    for line in output:gmatch("[^\n]+") do
        table.insert(lines, line)
    end

    vim.schedule(function()
        local line_count = vim.api.nvim_buf_line_count(self.active_bufnr)
        vim.api.nvim_buf_set_lines(self.active_bufnr, line_count + 1, -1, false, lines)
    end)
end

function NvllmUi:print_virtual(...)
    local arg = {...}
    local output = table.concat(arg, '\t') .. '\n'

    local lines = {}
    for line in output:gmatch("[^\n]+") do
        table.insert(lines, line)
    end

    local ns = vim.api.nvim_create_namespace("")

    vim.schedule(function()
        local line_count = vim.api.nvim_buf_line_count(self.active_bufnr) - 1
        vim.api.nvim_buf_set_extmark(self.active_bufnr, ns, line_count, -1, {
            virt_text = {{ table.concat(lines, '\n'), "Comment" }},
            virt_text_pos = "inline",
        })

        vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
            buffer = self.active_bufnr,
            callback = function()
                vim.api.nvim_buf_clear_namespace(self.active_bufnr, 0, 0, -1)
                return true
            end,
            desc = "Clear virtual text on buffer change",
        })
    end)
end

-- wrap text to the width of the window
---@param text string
---@param width number
function NvllmUi:wrap_text(text, width)
    local wrapped = {}
    local lines = vim.split(text, '\n')
    for _, line in ipairs(lines) do
        local line_remaining = line
        if #line_remaining <= width then
            table.insert(wrapped, line_remaining)
        end
        while #line_remaining > width do
            local segment = line_remaining:sub(1, width)
            local last_space = segment:match(".*%s()")

            segment = segment:sub(0, last_space - 1)
            line_remaining = line_remaining:sub(last_space)

            table.insert(wrapped, segment)

            if #line_remaining <= width then
                table.insert(wrapped, line_remaining)
            end
        end
    end

    return wrapped
end

-- wrap text to the width of the window and print it to the buffer
---@param text string
function NvllmUi:wrap_and_print(text)
    local width = self.config.dimensions.width

    self:print(table.concat(self:wrap_text(text, width), '\n'))
end

-- clear the buffer of all text
function NvllmUi:clear()
    vim.schedule(function()
        vim.api.nvim_buf_set_lines(self.active_bufnr, 0, -1, false, {})
    end)
end

function NvllmUi:update_config(config)
    self.config = config
end

return NvllmUi
