import * as d3 from "https://cdn.jsdelivr.net/npm/d3@7/+esm";

const res = await fetch("temperatures.json");
console.assert(res.status == 200);
const temperatures = (await res.json()).map(t => ({...t, time: new Date(t.time * 1000) }));

const chart = () => {
    const width = 800;
    const height = 600;

    const marginTop = 10;
    const marginRight = 20;
    const marginBottom = 20;
    const marginLeft = 40;

    const x = d3.scaleUtc(
        d3.extent(temperatures, t => t.time),
        [marginLeft, width - marginRight]
    );

    const y = d3.scaleLinear(
        [0, d3.max(temperatures, t => t.temperature)],
        [height - marginBottom, marginTop]
    );

    const svg = d3.create("svg")
        .attr("width", width)
        .attr("height", height)
        .attr("viewBox", [0, 0, width, height])
        .attr("style", "max-width: 100%; height: auto");

    // x-axis
    svg.append("g")
        .attr("transform", `translate(0,${height - marginBottom})`)
        .call(d3.axisBottom(x).ticks(width / 80).tickSizeOuter(0));

    // y-axis
    svg.append("g")
        .attr("transform", `translate(${marginLeft},0)`)
        .call(d3.axisLeft(y));

    // The actual line.
    const line = d3.line()
        .x(t => x(t.time))
        .y(t => y(t.temperature));

    svg.append("path")
        .attr("fill", "none")
        .attr("stroke", "steelblue")
        .attr("stroke-width", 1.0)
        .attr("d", line(temperatures));

    return svg.node();
};

container.append(chart());
