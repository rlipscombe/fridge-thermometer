#require "rocky.class.nut:2.0.2"

History <- {};

function saveHistory() {
    if (History.v != 0) {
        server.save(History);
    }
}

function loadHistory() {
    History <- server.load();
    if (!("v" in History)) {
        History.v <- 1;
        History.temps <- [];
    }
}

device.on("readings", function(data) {
    if (data.th) {
        local time_ms = time() * 1000;
        History.temps.push([time_ms, data.th.temperature]);
        if (History.temps.len() > 48 * 60) {
            History.temps.remove(0);
        }
    }

    saveHistory();
});

app <- Rocky();
app.get("/", function(context) {
    context.setHeader("Location", http.agenturl() + "/index.html");
    context.send(301);
});
app.get("/index.html", function(context) {
    context.send("@{include("index.html")|escape}");
});
app.get("/index.js", function(context) {
    context.send("@{include("index.js")|escape}");
});

app.get("/temperature.json", function(context) {
    context.setHeader("Content-Type", "text/json");
    context.send(History.temps);
});

loadHistory();
server.log(http.agenturl());
