local Job = require("plenary.job")

-- Clear the module cache
package.loaded["nvllm.ui"] = nil
package.loaded["nvllm.config"] = nil
package.loaded["nvllm.utils"] = nil
package.loaded["nvllm.network"] = nil

local Config = require("nvllm.config")
local Utils = require("nvllm.utils")
local Ui = require("nvllm.ui")
local Network = require("nvllm.network")

---@class Nvllm
---@field ui NvllmUi
---@field config NvllmConfig
---@field network Network
local Nvllm = {}

Nvllm.__index = Nvllm


---@return Nvllm
function Nvllm:new()
    local default_config = Config.get_default_config()

    return setmetatable({
        config = default_config,
        ui = Ui:new(default_config.ui),
        network = Network:new(default_config.chat)
    }, self)
end

---@return string
function Nvllm:get_prompt()
    local prompt = table.concat(Utils.get_visual_selection(), "\n")
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<esc>", true, false, true), "nx", true)
    return prompt
end

function Nvllm:invoke_llm()
    local prompt = self:get_prompt()

    self.network:curl_anthropic(prompt, function(status, text)
        if status == "error" then
            self.ui:print_virtual(text)
        else
            self.ui:wrap_and_print(text)
        end
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

    vim.api.nvim_create_user_command('Send', function()
        self:invoke_llm()
    end, {})

    vim.keymap.set({"v", "V", "n"}, "<leader>llm", function()
        self:invoke_llm()
    end, { noremap = true, silent = true })

    return self
end

return Nvllm
