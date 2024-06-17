@echo off

node bundle.js
move /Y "Movement.lua" "%localappdata%"
exit