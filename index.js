function ready() {
    var tempChart = $.plot("#temp-chart", [], {
        xaxis: { mode: "time" },
        lines: { show: true },
        points: { show: false }
    });

    function refresh() {
        $.get("temperature.json", function(data) {
            $("#last-temp").text(data[data.length - 1][1]);

            tempChart.setData([data]);
            tempChart.setupGrid();
            tempChart.draw();
        })
        .always(function() {
            setTimeout(refresh, 60000);
        });
    }

    refresh();
}

$(document).ready(ready);
