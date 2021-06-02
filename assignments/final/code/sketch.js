let gcoder;
let vertices;
let geom;

function setup() {
  createCanvas(windowWidth, windowHeight, WEBGL);

  gcoder = new GCoder();

  vertices = [];
  gcodeDraw();
}

function draw() {
  background(0);
  orbitControl(2, 2, 0.01);
  lights();
  normalMaterial();
  model(geom);
}

function gcodeDraw() {
  gcoder.autoHome();
  let s = 1000;
  gcoder.moveRetract(100, 100, 0.5, s);
  
  // let's make a vase!
  // some variables for printing:
  let step = TWO_PI / 100;
  let startHeight = 0.2;
  let maxHeight = 150;
  let layerHeight = 1;
  
  // and some vase parameterizations...
  let rb = 50;
  let amp = 10;
  
  for (let z = startHeight; z < maxHeight; z += layerHeight) {
    let a = map(z, startHeight, maxHeight, 0, 4 * TWO_PI);
    r = map(
      cos(map(z / maxHeight, 0, 1, 2, 0.5) * a),
      -1,
      1,
      rb - amp * cos(a) * (1 - z / maxHeight),
      rb + amp * cos(a) * (1 - z / maxHeight)
    );

    for (let t = 0; t < TWO_PI; t += step) {
      let x = r * cos(t) + 100;
      let y = r * sin(t) + 100;
      gcoder.moveExtrude(x, y, z, s);
    }
  }

  gcodeParse();
}

function gcodeParse() {
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
  });

  // finalize the geometry
  geom = new p5.Geometry(100, 140);
  geom.gid = random(1000);
  console.log(vertices.length);
  geom.vertices = vertices.slice(1); // remove origin
  geom.computeFaces();
  geom.computeNormals();
}
