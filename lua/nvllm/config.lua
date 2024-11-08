local M = {}
local Utils = require('nvllm.utils')

---@alias NvllmDimensions {width: number, height: number}

---@class NvllmUiConfig
---@field dimensions NvllmDimensions

---@class NvllmNetworkConfig
---@field system_prompt string
---@field apikey string
---@field model string

---@class NvllmConfig
---@field ui NvllmUiConfig
---@field chat NvllmNetworkConfig

---@return NvllmConfig
function M.get_default_config()
    local key, err = Utils.read_file(".env")
    if not key and not err then
        key = {}
    end
    return {
        ui = {
            dimensions = {
                width = 80,
                height = 30
            }
        },
        chat = {
            system_prompt = 'What follows is a conversation between a helpful assistant and someone whom they are assisting. You are that assistant, be concise',
            apikey = Utils.read_file(".env")["APIKEY"],
            model = "claude-3-5-sonnet-20240620"
        }
    }
end

function M.merge_config(config)
    local default = M.get_default_config()
    return vim.tbl_extend('force', default, config or {})
end

return M
