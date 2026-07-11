// Temperature/Humidity
#require "HTS221.device.lib.nut:2.0.1"

// Initially, every 5 seconds.
SLEEP_FOR_SECS_INIT <- 5;

// Every 15 minutes.
SLEEP_FOR_SECS_MAX <- 15 * 60;

// We have to keep the sleep value in 'nv' so that it's preserved during deep sleep.
if (!("nv" in getroottable()) || !("sleep" in nv)) {
    nv <- {sleep = SLEEP_FOR_SECS_INIT};
}

function sleepfor() {
    local secs = nv.sleep;

    // We start with a short sleep period and double it each time (up to a maximum).
    // This makes debugging easier, because you don't have to wait (e.g.) 15 minutes between the first two readings.
    nv.sleep *= 2;
    if (nv.sleep > SLEEP_FOR_SECS_MAX) {
        nv.sleep = SLEEP_FOR_SECS_MAX;
    }

    server.log(format("Sleeping for %d seconds", secs));
    return secs;
}

// onidle is called once we're running, connected, etc.
function onidle() {
    // Configure the temperature/humidity sensor.
    hardware.i2c89.configure(CLOCK_SPEED_400_KHZ);
    tempHumid <- HTS221(hardware.i2c89);

    tempHumid.setMode(HTS221_MODE.ONE_SHOT);

    // Read the temperature and report it to the server; when it completes, go back to sleep.
    tempHumid.read(function(data) {
        if ("error" in data) {
            server.error("Error while reading temperature: " + data.error);
        }
        else {
            server.log(format("Temperature: %0.2f °C, Humidity: %0.2f %%", data.temperature, data.humidity));
            agent.send("tempHumid", data);
        }

        server.sleepfor(sleepfor());
    });
}

imp.onidle(onidle);
