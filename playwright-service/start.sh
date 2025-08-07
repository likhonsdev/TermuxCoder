#!/bin/bash

# Start Xvfb (virtual display)
Xvfb :99 -screen 0 1280x720x16 &
export DISPLAY=:99

# Start VNC server
# The password 'pw' is hardcoded as expected by the frontend iframe src
x11vnc -passwd pw -display :99 -N -forever -bg

# Start the Playwright service
node server.js
