local Job = require('plenary.job')

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


return Network
