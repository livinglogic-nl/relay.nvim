# relay.nvim
- Run log tails and other tasks in a non-obtrusive way.

# Demo
[![relay.nvim demo on youtube](http://img.youtube.com/vi/Q-usLiX4KMY/0.jpg)](http://www.youtube.com/watch?v=Q-usLiX4KMY "relay.nvim demo")

# Technical overview

```
┌───────────────────────────────────┌───────────────sidebar───────────────┐
│                                   │ layout                              │
│                                   │┌───────────────────────────────────┐│
│                                   ││ 📕 source                         ││
│                                   ││                                   ││
│                                   ││                                   ││
│                                   │└───────────────────────────────────┘│
│                                   │┌───────────────────────────────────┐│
│                                   ││ 🎉 source                         ││
│                                   ││                                   ││
│                                   ││                                   ││
│                                   │└───────────────────────────────────┘│
│                                   │┌───────────────────────────────────┐│
│                                   ││ ⚡️ adhoc source                   ││
│                                   ││                                   ││
│                                   ││                                   ││
│                                   │└───────────────────────────────────┘│
└───────────────────────────────────└─────────────────────────────────────┘
```

## Sidebar
The sidebar is the main component of relay.nvim

The contents of the sidebar is determined by the current **layout**

### Layout
A layout is just a list of source names. Every source name should map to an actual **source**
```lua
{ "some.log.source", "another.source" }
```


### Source
A source has a name, optional icon and an **app**
```lua
{
    name = "some.log.source",
    icon = "📕",
    app = ...
}
```

### App
- As soon as a source is being viewed in the sidebar, the app will be started.
- An app remains running even when the sidebar is closed, or showing a differnt layout.
- If an app is considered unhealthy (it exited for example), it will be restarted as soon as it is displayed
```lua
{
    start = function() end, -- called to start this app,
    stop = function(ctx) end, -- called to stop this app, uses return calue from start
    parse = function(params) end, -- called to parse output buffers
    view = function(params) end, -- called to actually fill the neovim buffer
    action = function(params, row) end, -- optional: perform an action on a row
}
```

# Global setup
```lua
require('relay').setup({
    layouts = {
        { 'relay.log', 'party', },
    },
    sources = {
        {
            name = "relay.log",
            app = require('relay.apps.tail').create( nvimLogFile('relay.nvim.log'), parseLua),
            icon = "📕",
        },
        {
            name = "party",
            app = require('relay.apps.shell').create({ "cowsay", "its party time" }),
            icon = "🎉",
        },
    },
});
```

# Augmented local setup
Every time the sidebar opens, it will try to load additional setup from the current working directory.

If it exists, the configuration of global and local are combined.

```lua
-- "$CWD/relay.lua"
return {
    layouts = {
        { 'npm.dev', "relay.log" },
    },
    sources = {
        {
            name = "npm.dev",
            app = require('relay.apps.shell').create({ "npm", "run", "dev" }),
            icon = "🟢",
        },
    },
}
```

# Available methods
```lua
require('relay').toggle() -- opens or closes the sidebar

require('relay').nextLayout() -- Make the next layout the current layout
require('relay').prevLayout() -- Make the previous layout the current layout
require('relay').focusWindow(nr) -- Focus nth sidebar window (first is 1)

require('relay').action() -- Open actions menu (execute action on a line)

require('relay').adhoc(source) -- adds the adhoc source
require('relay').run(name, args) -- adds a named shell adhoc source with args
require('relay').runDefault(args) -- calls require('relay').run('default', args)
```

# Available commands
|command|see|
|---|---|
:RelayToggle|require('relay').toggle
:RelayNext|require('relay').nextLayout
:RelayPrev|require('relay').prevLayout
:RelayFocus [nr]|require('relay').focusWindow
:RelayAction|require('relay').action


