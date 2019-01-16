#require "rocky.class.nut:2.0.2"

server.log(__EI.DEPLOYMENT_ID);

History <- {};

function saveHistory() {
    if (History.v != 0) {
        server.save(History);
    }
}

function loadHistory() {
    History <- server.load();
    if (!("v" in History)) {
        History.v <- 2;
        History.temps <- [];

        server.save(History);
    }
    else if (History.v == 1) {
        History.v <- 2;

        foreach (k, v in History.temps) {
            History.temps[k][0] *= 1000;
        }

        server.log("Migrated history to v2");
        server.save(History);
    }

    server.log(format("Loaded history v%d, %d temperature readings", History.v, History.temps.len()));
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
