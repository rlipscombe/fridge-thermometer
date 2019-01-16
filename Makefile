all: build force-run

build: agent.nut_ device.nut_

run:
	impt build run

force-run:
	impt dg update --min-supported-deployment `impt build deploy -z json | jq -r '.Deployment.id'`
	impt dg restart

agent.nut_: agent.nut index.html index.js
	pleasebuild -l agent.nut > agent.nut_

device.nut_: device.nut
	pleasebuild -l device.nut > device.nut_

npm:
	npm install -g imp-central-impt@2.0.0
	npm install -g Builder@2.4.0
