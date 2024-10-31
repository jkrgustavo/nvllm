assert = require("luassert")

describe("Testing a test", function ()

    before_each(function ()
        local events = {}
        vim.api.nvim_buf_attach(0, false, {
            on_lines = function (foo, bar)
                table.insert(events, { foo, bar })
                print(events)
            end
        })
    end)


    it("random test", function ()
        assert.equals(true, true)
    end)

end)
