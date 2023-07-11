"use strict";

// Constants
const host = "192.168.2.102";
const port = "8000"


// Main 
_updateDraftState();
_updateTimer();

// Buttons
const startButton = document.querySelector('[name="start"]');
const stopButton = document.querySelector('[name="stop"]');

// Eventlistener
startButton.addEventListener("click", fetchStartButton);
stopButton.addEventListener("click", fetchStopButton);

// Functions
function fetchStopButton () {
    fetch(`http://${host}:${port}/stopqueue`);
}

function fetchStartButton () {
    fetch(`http://${host}:${port}/queuegame`);
}

function test(str) {
    alert(str);
}

function _changeBGColor(color) {
    document.body.style.backgroundColor = color;
}

function _updateTextElement(elementID,strValue) {
    document.getElementById(elementID).innerHTML = strValue;
}

async function _updateDraftState() {
    const sleep = (delay) => new Promise(resolve => {
        setTimeout(resolve, delay);
    });
    for (;; await sleep(1_000)) {
        const initext = await fetchTxt("state");
        var draftState; 
        draftState = initext.includes("False");            
        _updateTextElement("state",!draftState);  
        if (draftState) {
            _changeBGColor("red");
        } 		
        if (!draftState) {
            _changeBGColor("Green");
        } 		
    }	
}

async function _updateTimer() {
    const sleep = (delay) => new Promise(resolve => {
        setTimeout(resolve, delay);
    });

    let minutes = 0;
    let seconds = 0;
    for (;; await sleep(1_000)) {
        const timer = await fetchTxt("timer");
        minutes = Math.floor(timer/60);
        seconds = timer % 60;
        const time = minutes + 'min:' + seconds + 'sec';
        if (minutes > 89) {
            _updateTextElement("timer","0");
        } else {
            _updateTextElement("timer",time);
        }
    }
}

async function fetchTxt(txt) {		
    const r = await fetch(`http://${host}:${port}/${txt}`);
    const text = await r.text();
    return text;
}	
