// Accelerometer
#require "LIS3DH.device.lib.nut:2.0.2"

// Temperature/Humidity
#require "HTS221.device.lib.nut:2.0.1"

// Pressure
#require "LPS22HB.device.lib.nut:2.0.0"

// LED
#require "WS2812.class.nut:3.0.0"

hardware.i2c89.configure(CLOCK_SPEED_400_KHZ);
tempHumid <- HTS221(hardware.i2c89);

tempHumid.setMode(HTS221_MODE.ONE_SHOT);

pressureSensor <- LPS22HB(hardware.i2c89);
pressureSensor.softReset();

// 5v power on the impExplorer is gated; we need to enable pin 1.
hardware.pin1.configure(DIGITAL_OUT, 1);

Black <- [0, 0, 0];
Red <- [32, 0, 0];
Orange <- [32, 4, 0];
Yellow <- [32, 24, 0];
Green <- [0, 32, 0];
Cyan <- [0, 32, 18];
Blue <- [0, 4, 32];
Magenta <- [24, 0, 32];
Pink <- [32, 0, 16];

spi <- hardware.spi257;
pixels <- WS2812(spi, 1);
pixels.fill(Yellow);
pixels.draw();

function readSensors() {
    pixels.fill(Green);
    pixels.draw();

    readTemperature();
    readPressure();

    imp.wakeup(0.1, function() {
        pixels.fill(Black);
        pixels.draw();
    });
}

READINGS <- {
    th = null,
    p = null
};

function readTemperature() {
    tempHumid.read(function(result) {
        READINGS.th <- result;
        if ("error" in result) {
            server.error("Error while reading temperature: " + result.error);
        }
        else {
            server.log(format("Humidity: %0.2f %%, Temperature: %0.2f °C", result.humidity, result.temperature));
        }
    });
}

function readPressure() {
    // The pressure sensor also reports the temperature,
    // but -- allegedly -- it's not as accurate.
    pressureSensor.read(function(result) {
        READINGS.p <- result;
        if ("error" in result) {
            server.error("Error while reading pressure: " + result.error);
        }
        else {
            server.log(format("Pressure: %0.2f hPa, Temperature: %0.2f °C", result.pressure, result.temperature));
        }
    });
}

function postReadings() {
    agent.send("readings", READINGS);
}

function loop() {
    readSensors();
    postReadings();

    imp.wakeup(60.0, loop);
}

function onconnect(state) {
    if (state == SERVER_CONNECTED) {
        server.log("Using SSID:     " + imp.getssid());
        server.log("Using BSSID:    " + imp.getbssid());
    }
    else {
        server.disconnect();
        server.connect(onconnect, 10);
    }
}

function onunexpecteddisconnect(reason) {
    server.disconnect();
    server.connect(onconnect, 10);
}

server.setsendtimeoutpolicy(RETURN_ON_ERROR, WAIT_TIL_SENT, 10);
server.onunexpecteddisconnect(onunexpecteddisconnect);

if (server.isconnected()) {
    onconnect(SERVER_CONNECTED);
}
else {
    server.connect(onconnect, 10);
}

server.log("Device ID:      " + hardware.getdeviceid());
server.log("MAC Address:    " + imp.getmacaddress());
server.log("Improm Version: " + imp.getsoftwareversion());

imp.wakeup(0.2, function() {
    pixels.fill(Black);
    pixels.draw();
});

imp.wakeup(0.5, function() {
    loop();
});
