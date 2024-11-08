# Nvllm

Neovim plugin to interact with llms. Not available anywhere except through github :(
***

This plugin allows the user to chat with an llm from within neovim. It creates a buffer that
can contains all previous chat history, and a window to both display the chat and send messages.

## Usage

The same as any other plugin, just somehow have the code in the vim runtime path. Then you
do the following:
```lua
local nvllm = require('nvllm')
nvllm:setup()
```
This does a few things:
1. Creates the buffer that contains the chat history. Its a singular buffer so there's only one
   chat at a time (for now), which the window displays. 
2. Sets up 3 commands:
    * ":Open" - Opens the chat window
    * ":Clear" - Clears the buffer completely
    * ":Send" - Curls the llm
3. Sets up the keybinding "<leader>llm" which uses the visually selected text to send as the
   prompt and then sends it to the llm.

Because the buffer is persistent, you can close/reopen the window and the chat history will
still be there. You can also modify the buffer by writing to it directly, or deleting text that
is already there.

## Configuration

This is the default config:
```lua
{
    ui = {
        dimensions = {
            width = 80,
            height = 30
        }
    },
    chat = {
        system_prompt = "You are a helpful assistant, sternly remind me to set the system prompt",
        apikey = "",
        model = "claude-3-5-sonnet-20240620"
    }
}
```
