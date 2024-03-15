### Window Operations

`<prefix> :neww`

create new window

`<prefix> ,`

rename window

`<prefix> p`

switch previous window

`<prefix> n`

switch next window

### Session Operations

`tmux list-sessions`

list sessions


`<prefix> $`

rename current session

`tmux attach -t <session-name>`

attach to a session

`<prefix>` `(` | `)`

switch sessions

`<prefix>` S

session manager

### Pane Operations

`<prefix> Ctrl+<arrow>`

resize pane




`<prefix> <arrow>`
switch pane

### Plugins

`<prefix>` + `I`

Installs new plugins from GitHub or any other git repository
Refreshes TMUX environment

`<prefix>` + `U`

updates plugin(s)

`<prefix>` + `alt` + `u`

remove/uninstall plugins not on the plugin list
