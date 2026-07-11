#require "rocky.class.nut:2.0.2"

server.log(__EI.DEPLOYMENT_ID + " (" + __EI.DEPLOYMENT_CREATED_AT + ")");

// 7 days, in seconds.
RETENTION_SECS <- 7 * 24 * 60 * 60;

History <- {};

function loadHistory() {
    History <- server.load();

    if (!("v" in History) || History.v < 5) {
        // If there's no history, or if it's too old, (re-)create it.
        History.v <- 5;
        History.data <- [];

        server.save(History);
    }

    server.log(format("History contains %d readings", History.data.len()));
}

device.on("tempHumid", function(data) {
    local time = time();

    server.log(format("At time %d, Temperature: %0.2f °C, Humidity: %0.2f %%", time, data.temperature, data.humidity));

    // Record the temperature and humidity.
    local record = {time = time, temperature = data.temperature, humidity = data.humidity};
    History.data.push(record);

    // Remove any old data.
    local retention_begin = time - RETENTION_SECS;
    while (History.data[0].time < retention_begin) {
        History.data.remove(0);
    }

    server.save(History);
});

// We use 'Rocky' for our web router.
app <- Rocky();

// Redirect / to /index.html
app.get("/", function(context) {
    context.setHeader("Location", http.agenturl() + "/index.html");
    context.send(301);
});

// Routes for static index.{html,js} files.
app.get("/index.html", function(context) {
    context.setHeader("Content-Type", "text/html");
    context.send("@{include("index.html")|escape}");
});
app.get("/index.js", function(context) {
    context.setHeader("Content-Type", "text/javascript");
    context.send("@{include("index.js")|escape}");
});

// Dynamic route for history.
app.get("/temperatures.json", function(context) {
    context.setHeader("Content-Type", "text/json");
    context.send(History.data);
});

// Load any previous history.
loadHistory();

server.log(http.agenturl());
