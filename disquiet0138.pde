import processing.video.*;
Movie myMovie;

import oscP5.*;
import netP5.*;
OscP5 oscP5;
NetAddress superCollider;

int x = 1280;
int y = 720;
int r_limit=0, g_limit=0, b_limit = 0;
float maxDiff = 0;
boolean first = true;

// The pixel values has to be [limit] smaller than the recorded background color in order to be accounted for.
// Set a higher value for less data.
int limit = 70;

void setup() {
  size(1280,720);
  frameRate(30);
  //Init OSC. Do this before loading the movie file! Will crash otherwise
  oscP5 = new OscP5(this,57120);
  superCollider = new NetAddress("127.0.0.1", 57120);
  
  myMovie = new Movie(this, "/Path/to/movie");
  //change the following line to myMovie.loop(); for endless playback. No change in SuperCollider needed.
  myMovie.play();
}

void draw() {
  image(myMovie,0,0);
  println(frameRate);
}

// Called every time a new frame is available to read
void movieEvent(Movie m) {
  m.read();
  PImage frame_data = m.get();
  frame_data.loadPixels();
  
  for(int i = 0; i < width; i++){
    int xpos = i;
    int pixs = 0;
    float accu = 0;
    for(int j = 0; j < height; j++){
      color c = frame_data.pixels[i*j];
      
      // Read the colors the fast way.
      int r = (c >> 16) & 0xFF;
      int g = (c >> 8) & 0xFF;
      int b = c & 0xFF;
      
      // Find the frame background color from the top leftmost pixel .... (yes yes, not fantastic)
      if(first) {
        r_limit = r - limit;
        g_limit = g - limit;
        b_limit = b - limit;
        maxDiff = r_limit+g_limit+b_limit;
        first = false;
      }
      
      // Filter out stuff other than BG
      if(r < r_limit && g < g_limit && b < b_limit) {
        
        // Starting as 0 indexed, then adding 1
        
        float ypos = j + 1;
        
        // Find the color difference based on the rgb sum difference from the max diff according to the limit colors
        // Wow.. That makes no sense at all!
        float pdiff = (r_limit - r) + (g_limit - g) + (b_limit - b);
        float diff = pdiff / maxDiff;
        
        pixs++;
        accu += diff*(ypos/720);
        
        //println("xpos:", xpos, "ypos:", ypos, "diff", diff);
      }
      
    }
    if(pixs != 0){
      //println("dark pixels", pixs);
      //println("accu diff:", accu);
      toSC(xpos,pixs,accu);
    }
  }
  
}

void toSC(int xp, int yp, float df){
  OscMessage msg = new OscMessage("/test");
  msg.add(xp);
  msg.add(yp);
  msg.add(df);
  oscP5.send(msg,superCollider);
}
