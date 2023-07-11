// Imports
const http = require("http");
const fs = require("fs").promises;
const fss = require("fs");
const net = require("net");

// variables

// Open ipconfig and get your machines IPv4 adress
// on windos: open cmd, type ipconfig, entry IPv4-Adress
const host = "192.168.2.163";
const port = "8000";
const tcpHost = "127.0.0.1";
const tcpPort = "13300";

let jsFile;
let indexHTML;

let tcpQueueGame = "queueGame:False";
let tcpTimer = 0;
let gameState = "gameState:False";

const serverTCP = net.createServer((socket) => {
  socket.write(tcpQueueGame);
  socket.on("data", (message) => {
    let msg = message.toString();
    if (msg == "queueGame:False") {
      //console.log(message.toString())
      tcpQueueGame = "queueGame:False";
    }
    if (msg == "gameState:True") {
      //console.log("Draft Live")
      gameState = "gameState:True";
    }
    if (msg == "gameState:False") {
      gameState = "gameState:False";
    }
    if (!isNaN(msg)) {
      tcpTimer = msg;
    }
  });
});

serverTCP.listen(tcpPort, tcpHost);
console.log("TCP Server Runs");

const requestListener = function (req, res) {
  switch (req.url) {
    // API endpoints
    case "/timer":
      res.setHeader("Content-Type", "text/plain");
      res.writeHead(200);
      res.end(tcpTimer);
      break;
    case "/queuegame":
      console.log("Queue Started!");
      tcpQueueGame = "queueGame:True";
      res.writeHead(200);
      res.end();
      break;
    case "/stopqueue":
      console.log("Queue stopped!");
      tcpQueueGame = "queueGame:Stop";
      res.writeHead(200);
      res.end();
      break;
    case "/client.js":
      res.setHeader("Content-Type", "text/javascript");
      res.writeHead(200);
      res.end(jsFile);
      break;
    case "/state":
      res.setHeader("Content-Type", "text/plain");
      res.writeHead(200);
      res.end(gameState);
      break;
    case "/":
      res.setHeader("Content-Type", "text/html");
      res.writeHead(200);
      res.end(indexHTML);
      break;
    default:
      res.setHeader("Content-Type", "text/html");
      res.writeHead(404);
      res.end("Page does not exist");
  }
};

// Server Object
const server = http.createServer(requestListener);
_startServer();

// Run Server
function _startServer() {
  indexHTML = _readFile("index.html");
  redirectPage = _readFile("redirect.html");
  jsFile = _readFile("client.js");
  server.listen(port, host, () => {
    console.log(`Server is running on http://${host}:${port}`);
  });
}

// returns static files preload
function _readFile(contentPath) {
  try {
    const data = fss.readFileSync(__dirname + "/" + contentPath, "utf8");
    return data;
  } catch (err) {
    console.error(`Could not read redirect.html file : ${err}`);
    process.exit(1);
  }
}
