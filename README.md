# relay.nvim

# Goal
Provide a way to view logs, long running tasks and short running tasks in an non-obtrusive way.

# Preview

```
-----------
|    |llll|
|    |ssss|
|    |jjjj|
-----------
```

# Initialize

```lua
-- initialize:
local relay = require('relay')
relay.config({
    sources = {
        {
            name = "relay.log",
            app = require('relay.apps.tail').create( nvimLogFile('relay.nvim.log'), parseLua),
            icon = "📕",
        },
        {
            name = "date",
            app = require('relay.apps.shell').create({ "date" }),
            icon = "🕥",
        },
    },
    layouts = {
        { 'relay.log', 'date', },
    },
});
```

# Open/close the sidebar

```lua
-- relay.open();
-- relay.close();
relay.toggle();
```

# Run adhoc shells

```lua
relay.run('zsh.shell', { 'zsh' });
```

# Much more readme coming soon!
