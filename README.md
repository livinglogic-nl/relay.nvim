# relay.nvim (under construction)

# goal
Provide a way to view logs, long running tasks and short running tasks in an non-obtrusive way.

# preview

```
-----------
|    |llll|
|    |ssss|
|    |jjjj|
-----------
```

# configuration

The user can configure relay layouts globally and workdir specific:

```sh
~/relay.lua
$CWD/relay.lua
```

## example

```lua
return {
    lineToLog = {
        ["lua-json-log"] = function(line)
            local ok,obj = pcall(function()
                return vim.fn.json_decode(line);
            end)
            if not ok then return nil end
            return {
                type = obj.level,
                unix = obj.date * 1000,
                text = obj.msg,
            }
        end
    },
    sources = {
        { name="log.nvim", type = "log", url = "/tmp/nvim-lua", l2l = "lua-json-log" },
        { name="log.hammerspoon", type = "log", url = "/tmp/hs-lua", l2l = "lua-json-log" },
    },
    layouts = {
        {
            "log.nvim",
            "log.hammerspoon",
        },
        {
            "log.nvim",
        },
    }
}
```



