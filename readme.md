# DOTA2 auto accept and remote queue

This project runs a http server that also runs a TCP server which autoIT is broadcasting too.
AutoIT itself detects the game states with
pixel detection and OCR algorithms. You can connect with any device to the website
that runs locally to check out the queue state. You are able to start the queue
and stop the queue, as well as being able to see if a game was found. The script
automatically accepts the game invite.
Never miss a game again!

Provides some more functionallity during games:

- Detects game start with OCR algorithms.
- Objective announcements via sound files (Runes, ...).
- Starts roshan time on F6 press.
- Remote queue start and stop.
- Remote announcement if game is found.
- Automatically accepts games if found.

## Requirements

- Latest autoIT version https://www.autoitscript.com/site/autoit/downloads/
- nodeJS https://nodejs.org/en
- Port 8000 opened on your machine to be accesible within your local network!

## Setup

- Clone the repo
- run "npm install"
- run ipconfig and get your machines IPv4 adress and add it to server.js host
- run the server "node server.js"
- run auto_accept_pixel_reborn.au3
- You can now reach the server via http at http://<yourIPv4Adress>:8000/

# Notes

- Pixel checksums are not updated for current DOTA2 patch.
- Pixel cheksums can differ on different hardware and drivers. They need to be adjusted on certain machines.
