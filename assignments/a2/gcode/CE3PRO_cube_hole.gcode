let gcoder;
let capture;
let step;
let vertices;

let renderer;
let geom;
let gid = "custom";
function setup() {
  step = TWO_PI / 50;
  layerHeight = 0.2;
  createCanvas(400, 400, WEBGL);
  // capture = createCapture(VIDEO);
  // capture.size(960, 720);
  gcoder = new GCoder();
  //   gcoder.on("ok", gcoder.serial_ok);
  //   gcoder.serial.requestPort();
  //   gcoder.serial.on("noport", function () {
  //     // we don't have access to any ports yet, so we need to request them.
  //     // add an event listener for a user clicking on the page
  //     document.addEventListener(
  //       "click",
  //       function () {
  //         gcoder.serial.requestPort();
  //       },
  //       { once: true }
  //     );
  //   });

  //   gcoder.serial.on("portavailable", function () {
  //     // we have a serial port; ender wants to talk at 115200
  //     gcoder.serial.open({ baudRate: "115200" });
  //   });

  //   gcoder.serial.on("requesterror", function () {
  //     console.log("error!");
  //   });

  //   gcoder.serial.on("open", gcodeDraw);
  //   gcoder.serial.on("data", onData);

  // createCanvas(400, 400, WEBGL);
  // createEasyCam();
  // document.oncontextmenu = () => false;

  vertices = [];
  console.log('new geom');
  geom = new p5.Geometry(43,43);
  console.log('off to draw');
  gcodeDraw();
}

function draw() {
  background(255);
  orbitControl(1,1, 0.01);
  // normalMaterial();
  lights();

  // geom.vertices = vertices;
  // geom.computeFaces();
  // geom.computeNormals();
  // renderer.createBuffers(gid, geom);
  // renderer.drawBuffers(gid);
  model(geom);

  // noFill();
  // beginShape();
  // for (let idx = 0; idx < vertices.length; idx++) {
  //   var v1 = vertices[idx];
  //   vertex(v1.x, v1.y, v1.z);
  // }
  // endShape();

  // console.log(frameRate());
}

function gcodeDraw() {
  console.log('gonna draw!');
  gcoder.autoHome();
  let s = 1000;
  gcoder.moveRetract(100, 100, 0.5, 3 * s);
  let z = 0.2;
  let step = TWO_PI / 50;
  let r = 10;
  let startHeight = 0.2;
  let maxHeight = 100;
  let layerHeight = 1;
  let rb = 50;
  let amp = 5;
  // vase
  for (let z = startHeight; z < maxHeight; z += layerHeight) {
    let a = map(z, startHeight, maxHeight, 0, 4 * TWO_PI);
    r = map(
      cos(map(z / maxHeight, 0, 1, 2, 0.5) * a),
      -1,
      1,
      rb - 5 * cos(a) * (1 - z / maxHeight),
      rb + 5 * cos(a) * (1 - z / maxHeight)
    );

    console.log(rb - (1 - z / maxHeight));
    for (let t = 0; t < TWO_PI; t += step) {
      let x = r * cos(t) + 100;
      let y = r * sin(t) + 100;
      gcoder.moveExtrude(x, y, z, s);
    }
  }
    
    // helix
//     gcoder.moveRetract(100, 100, 0.5, 3 * s);
//     for (let t = 0; t < 6 * TWO_PI; t += step) {
//       let x = r * cos(t) + 100;
//       let y = r * sin(t) + 100;
//       gcoder.moveExtrude(x, y, z, 12);

//       z += 0.03;
//     }

  console.log('time to parse');
  gcoder.commands.forEach((cmd) => {
    cmd = cmd.trim().split(" ");
    var code = cmd[0].substring(0, 2);
    if (code !== "G1") {
      //G1 are extrusion commands. assume never extrude on G0
      return;
    }

    var newV = new p5.Vector();
    cmd.forEach((c) => {
      switch (c.charAt(0)) {
        case "X":
          newV.x = c.substring(1);
          break;
        case "Y":
          newV.z = c.substring(1); // switch z-x
          break;
        case "Z":
          newV.y = c.substring(1); // switch z-x
          break;
        case "E":
          if (c.substring(1) < 0) {
            return;
          }
      }
    });
    vertices.push(newV);

    var newarr = (function (arr) {
      var m = {},
        newarr = [];
      for (var i = 0; i < arr.length; i++) {
        var v = arr[i];
        if (!m[v]) {
          newarr.push(v);
          m[v] = true;
        }
      }
      return newarr;
    })(vertices);

    vertices = newarr;
  });

  // geom = new p5.Geometry(1, 1, constructGeom());
  console.log('render bender');
  console.log('here');
  geom.vertices = vertices.slice(1);
  // geom.lineVertices = vertices;
  console.log(vertices.length);
  console.log('now here');
  geom.computeFaces();
  console.log('an here');
  geom.computeNormals();
  console.log('and there');
}

function onData() {
  let lineFeedChar = 10;
  let incomingChar = gcoder.serial.readBytes();
  let resp = "";
  if (incomingChar[incomingChar.length - 1] == lineFeedChar) {
    for (let i = 0; i < incomingChar.length; i++) {
      resp += String.fromCharCode(incomingChar[i]);
    }
  }

  console.log("The response is: " + incomingChar);
  if (resp.search("k") > -1 || resp == "\n") {
    // eek... sometimes o and k come in different packets!
    console.log(resp.search("k") > 0);
    gcoder.emit("ok", gcoder);
  } else {
    console.log("u dont got it");
  }
}
