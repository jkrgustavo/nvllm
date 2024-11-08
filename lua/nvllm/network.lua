local Job = require('plenary.job')
local Utils = require('nvllm.utils')

---@class Network
---@field config NvllmNetworkConfig
---@field curl_args table<string>?
---@field active_job any?
local Network = {}
Network.__index = Network

function Network:new(config)
    return setmetatable({
        config = config,
        active_job = nil,
        curl_args = nil
    }, self)
end


---@param prompt string
function Network:create_curl_args(prompt)
    local opts = self.config
    local url = "https://api.anthropic.com/v1/messages"

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

    vim.print(Utils.pretty_table_format(opts))

    if opts.apikey then
        table.insert(args, "-H")
        table.insert(args, "x-api-key: " .. opts.apikey)
        table.insert(args, "-H")
        table.insert(args, "anthropic-version: 2023-06-01")
    end


    self.curl_args = args
end

---@param prompt string
---@param handle_data_fn fun(status: string|nil, text: string): nil
function Network:curl_anthropic(prompt, handle_data_fn)
    if self.active_job ~= nil then
        self.active_job:shutdown()
        self.active_job = nil
    end

    self:create_curl_args(prompt)

    self.active_job = Job:new({
        command = 'curl',
        args = self.curl_args,
        on_exit = function(data)

            local json = vim.json.decode(data:result()[1])
            local text = ""
            local status = nil

            if json.type == "error" then
                text = "API Error: " .. json.error.type .. " - " .. json.error.message
                status = "error"
            elseif json.type == "message" then
                text = json.content[1].text
            end

            handle_data_fn(status, text)

        end,

    }):start()
end


return Network
