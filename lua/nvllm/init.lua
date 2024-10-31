local Job = require("plenary.job")

-- Clear the module cache
package.loaded["nvllm.ui"] = nil
package.loaded["nvllm.config"] = nil
package.loaded["nvllm.utils"] = nil

local Config = require("nvllm.config")
local Utils = require("nvllm.utils")
local Ui = require("nvllm.ui")

local active_job = nil

---@class Nvllm
---@field ui NvllmUi
---@field config NvllmConfig
local Nvllm = {}

Nvllm.__index = Nvllm

---@return string | nil
function Nvllm:get_prompt()
    local prompt = table.concat(Utils.get_visual_selection(), "\n")
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<esc>", true, false, true), "nx", true)
    return prompt
end

function Nvllm:create_curl_args()
    local opts = self.config.chat
    local url = "https://api.anthropic.com/v1/messages"

    local prompt = self:get_prompt()

    local data = {
        system = opts.system_prompt,
        messages = { { role = 'user', content = prompt } },
        model = opts.model,
        stream = false,
        max_tokens = 4096,
    }

    local args = {
        "-N",
        "-X", "POST",
        url,
        "-H", "Content-Type: application/json",
        "-d", vim.json.encode(data)
    }

    if opts.apikey then
        table.insert(args, "-H")
        table.insert(args, "x-api-key: " .. opts.apikey)
        table.insert(args, "-H")
        table.insert(args, "anthropic-version: 2023-06-01")
    end

    return args
end

---@param handle_data_fn fun(json: any): nil
function Nvllm:curl_anthropic(handle_data_fn)
    if active_job ~= nil then
        active_job:shutdown()
        active_job = nil
    end

    local args = self:create_curl_args()

    active_job = Job:new({
        command = 'curl',
        args = args,
        on_exit = function(data)
            vim.schedule(function()
                local json = vim.json.decode(data:result()[1])
                handle_data_fn(json)
            end)
        end
    })

    active_job:start()

end

---@return Nvllm
function Nvllm:new()
    local default_config = Config.get_default_config()

    return setmetatable({
        ui = Ui:new(default_config.ui),
        config = default_config
    }, self)
end

function Nvllm:handle_data(json)
    if json.type == "error" then
        self.ui:print("API Error: " .. json.error.type .. " - " .. json.error.message)
    elseif json.type == "message" then
        self.ui:print_llm_response(json.content[1].text)
    end
end

function Nvllm:invoke_llm()
    self:curl_anthropic(function(json)
        self:handle_data(json)
    end)
end

local nvllm_instance = Nvllm:new()

---@param self Nvllm
---@param opts NvllmConfig
---@return Nvllm
function Nvllm:setup(opts)
    if self ~= nvllm_instance then
        self = nvllm_instance
    end

    self.config = Config.merge_config(opts)
    self.ui:update_config(self.config.ui)

    vim.api.nvim_create_user_command('Open', function()
        self.ui:open_window()
    end, {})

    vim.api.nvim_create_user_command('Clear', function()
        self.ui:clear()
    end, {})

    vim.keymap.set({"v", "n"}, "<leader>llm", function()
        self:invoke_llm()
    end, { noremap = true, silent = true })

    vim.api.nvim_create_user_command('Send', function()
        self:curl_anthropic(function(json)
            self:handle_data(json)
        end)
    end, {})

    vim.api.nvim_create_user_command('Test', function()
        local text = {
            "This is some text, this should be split along newlines.",
            "More text containing numbers and special characters: 123456?",
            "The itsey bitsey spider went up the water spout. Down came the rain and washed the spider out.",
            "The last line is the most important. It, like the one above, should have more characters than the width of the window. This way proper wrapping can be tested. Blah Blah Blah Blabbah Blah"
        }

        self.ui:print_llm_response(table.concat(text, '\n'))
    end, {})

    return self
end

return Nvllm
