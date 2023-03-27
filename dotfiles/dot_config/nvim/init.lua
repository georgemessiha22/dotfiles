-- [[
--  File: init.lua
--  Description: Entry point file for neovim
-- ]]

local config = require("config")
-- Bootsraping plugin manager
config.bootstrap()
-- Load plugins
config.SetupPlugins()
-- Settings
config.load_config()
