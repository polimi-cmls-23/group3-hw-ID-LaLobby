import java.nio.*;
import KinectPV2.*;
import oscP5.*;
import netP5.*;
import controlP5.*;
import java.util.*;

KinectPV2 kinect;
ControlP5 cp5;
OscP5 oscP5;
NetAddress myRemoteLocation;

float r_h_x;
float r_h_y;
float l_h_x;
float l_h_y;
Slider r_h_x_slider;
Slider r_h_y_slider;
Slider l_h_x_slider;
Slider l_h_y_slider;

int  vertLoc;

//transformations
float a = 3.14;
int zval = 1100;
float scaleVal = 300;


//value to scale the depth point when accessing each individual point in the PC.
float scaleDepthPoint = 100.0;

//Distance Threashold
int maxD = 2500; // 4m
int minD = 0;  //  0m

//openGL object and shader
PGL     pgl;
PShader sh;

//VBO buffer location in the GPU
int vertexVboId;

public void setup() {
  size(1820, 980, P3D);
    frameRate(30);
  oscP5 = new OscP5(this, 7001);
  cp5 = new ControlP5(this);
  List l = Arrays.asList("Delay", "Reverb", "Phaser", "Flanger", "Distortion", "Harmonizer", "Tremolo", "Chorus", "None");
  
  cp5.addSlider("maxD")
     .setCaptionLabel("Visualizer max thresh")
     .setPosition(225,height - 65)
     .setRange(0,4000)
     .setSize(250,20)
     .setColorBackground(color(120, 120, 120))
     .setColorForeground(color(180, 180, 180))
     ;
     
  cp5.addSlider("minD")
     .setCaptionLabel("Visualizer min thresh")
     .setPosition(1250,height - 65)
     .setRange(0,4000)
     .setSize(250,20)
     .setColorBackground(color(120, 120, 120))
     .setColorForeground(color(180, 180, 180))
     ;
     
  l_h_y_slider = cp5.addSlider("l_h_y")
     .setCaptionLabel("Ly")
     .setPosition(100, 100)
     .setRange(0,1)
     .setValue(l_h_y)
     .setSize(20,250)
     .setColorBackground(color(120, 120, 120))
     .setColorForeground(color(180, 180, 180))
     ;   
     
  l_h_x_slider=cp5.addSlider("l_h_x")
     .setCaptionLabel("Lx")
     .setPosition(150, 100)
     .setRange(0,1)
     .setValue(l_h_x)
     .setSize(250,20)
     .setColorBackground(color(120, 120, 120))
     .setColorForeground(color(180, 180, 180))
     ;  
     
  r_h_y_slider=cp5.addSlider("r_h_y")
     .setCaptionLabel("Ry")
     .setPosition(1680,100)
     .setRange(0,1)
     .setValue(r_h_y)
     .setSize(20,250)
     .setColorBackground(color(120, 120, 120))
     .setColorForeground(color(180, 180, 180))
     ;   
     
  r_h_x_slider=cp5.addSlider("r_h_x")
     .setCaptionLabel("Rx")
     .setPosition(1400,100)
     .setRange(0,1)
     .setValue(l_h_x)
     .setSize(250,20)
     .setColorBackground(color(120, 120, 120))
     .setColorForeground(color(180, 180, 180))
     ;     
  
  cp5.addScrollableList("dropdown1")
    .setCaptionLabel("Select Right Effect")
    .setPosition(1320, 150)
    .setSize(200, 300)
    .setBarHeight(30)
    .setItemHeight(30)
    .addItems(l)
    .setOpen(false)
    .setColorBackground(color(120, 120, 120))
    .setColorForeground(color(180, 180, 180))
    ;
    
  cp5.addScrollableList("dropdown2")
    .setCaptionLabel("Select Left Effect")
    .setPosition(270, 150)
    .setSize(200, 300)
    .setBarHeight(30)
    .setItemHeight(30)
    .addItems(l)
    .setOpen(false)
    .setColorBackground(color(120, 120, 120))
    .setColorForeground(color(180, 180, 180))
    ;
    
  myRemoteLocation = new NetAddress("127.0.0.1", 57120);

  kinect = new KinectPV2(this);

  kinect.enableDepthImg(true);

  kinect.enablePointCloud(true);

  kinect.setLowThresholdPC(minD);
  kinect.setHighThresholdPC(maxD);

  kinect.init();

  sh = loadShader("frag.glsl", "vert.glsl");

  PGL pgl = beginPGL();

  IntBuffer intBuffer = IntBuffer.allocate(1);
  pgl.genBuffers(1, intBuffer);

  //memory location of the VBO
  vertexVboId = intBuffer.get(0);

  endPGL();
}

public void draw() {
  background(0);

  //draw the depth capture images
  //image(kinect.getDepthImage(), 0, 0, 320, 240);
  //image(kinect.getPointCloudDepthImage(), 320, 0, 320, 240);

  //translate the scene to the center
  translate(width / 2, height * 3 / 4, zval);
  scale(scaleVal, -1 * scaleVal, scaleVal);
  rotate(a, 0.0f, 1.0f, 0.0f);

  // Threahold of the point Cloud.
  kinect.setLowThresholdPC(minD);
  kinect.setHighThresholdPC(maxD);

  //get the points in 3d space
  FloatBuffer pointCloudBuffer = kinect.getPointCloudDepthPos();

  // obtain XYZ the values of the point cloud
  /*
  stroke(0, 0, 0);
  for(int i = 0; i < kinect.WIDTHDepth * kinect.HEIGHTDepth; i+=3){
      float x = pointCloudBuffer.get(i*3 + 0) * scaleDepthPoint;
      float y = pointCloudBuffer.get(i*3 + 1) * scaleDepthPoint;
      float z = pointCloudBuffer.get(i*3 + 2) * scaleDepthPoint;
      
   
      point(x, y, z);
   }
   */

  //begin openGL calls and bind the shader
  pgl = beginPGL();
  sh.bind();

  //obtain the vertex location in the shaders.
  //useful to know what shader to use when drawing the vertex positions
  vertLoc = pgl.getAttribLocation(sh.glProgram, "vertex");

  pgl.enableVertexAttribArray(vertLoc);

  //data size times 3 for each XYZ coordinate
  int vertData = kinect.WIDTHDepth * kinect.HEIGHTDepth * 3;

  //bind vertex positions to the VBO
  {
    pgl.bindBuffer(PGL.ARRAY_BUFFER, vertexVboId);
    // fill VBO with data
    pgl.bufferData(PGL.ARRAY_BUFFER,   Float.BYTES * vertData, pointCloudBuffer, PGL.DYNAMIC_DRAW);
    // associate currently bound VBO with shader attribute
    pgl.vertexAttribPointer(vertLoc, 3, PGL.FLOAT, false,  Float.BYTES * 3, 0 );
  }
  
   // unbind VBOs
  pgl.bindBuffer(PGL.ARRAY_BUFFER, 0);

  //draw the point buffer as a set of POINTS
  pgl.drawArrays(PGL.POINTS, 0, vertData);

  //disable the vertex positions
  pgl.disableVertexAttribArray(vertLoc);

  //finish drawing
  sh.unbind();
  endPGL();

  
  camera();
  noLights();
  stroke(255);
  noFill();
  fill(255);
  text(round(frameRate) + " fps", 50, height - 50);
  push();
  textSize(60);
  text("TELEKINESIS", width/2-180, 170);
  pop();
}

void dropdown1(int n) {
  
  OscMessage myMessage = new OscMessage("/dx");
  
  myMessage.add(n); /* add an int to the osc message */

  /* send the message */
  oscP5.send(myMessage, myRemoteLocation); 
}

void dropdown2(int n) {
  
  OscMessage myMessage = new OscMessage("/sx");
  
  myMessage.add(n); /* add an int to the osc message */

  /* send the message */
  oscP5.send(myMessage, myRemoteLocation); 
}

/* incoming osc message are forwarded to the oscEvent method. */
void oscEvent(OscMessage theOscMessage) {
  /* print the address pattern and the typetag of the received OscMessage */
  if(theOscMessage.checkAddrPattern("/p1/hand_r:tx")==true) {r_h_x_slider.setValue(theOscMessage.get(0).floatValue());}
  if(theOscMessage.checkAddrPattern("/p1/hand_r:ty")==true) {r_h_y_slider.setValue(theOscMessage.get(0).floatValue());}
  if(theOscMessage.checkAddrPattern("/p1/hand_l:tx")==true) {l_h_x_slider.setValue(theOscMessage.get(0).floatValue());}
  if(theOscMessage.checkAddrPattern("/p1/hand_l:ty")==true) {l_h_y_slider.setValue(theOscMessage.get(0).floatValue());}
}
