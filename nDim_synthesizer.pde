/**
 * four dimensional goodness - ben fry
 * originally completed sometime in december of 2000,
 * updated for processing in february 2005
 *
 * based largely on what i learned/ported from HYPRCUBE.BAS
 * found in the following article by Ken Holmes (kholmes@melbpc.org.au)
 * http://www.melbpc.org.au/pcupdate/9907/9907article10.htm
 *
 * now here:
 * https://web.archive.org/web/20020225043420/http://www.melbpc.org.au/pcupdate/9907/9907article10.htm

 * this was my initial code to figure out how these things work,
 * which i later ported up to an arbtitrary number of dimensions
 * for the "atmosphere" project. see:
 * http://acg.media.mit.edu/projects/atmosphere
 * http://acg.media.mit.edu/people/fry/atmosphere
 *
 *      space   to enable/disable auto-movement
 *      ?       to show/hide the text
 *
 *      1 2 3   to manually rotate with respect to each plane
 *      c       to change rotation randomly in one direction
 *      
 *      v       show coordinates labels
 *      b       show binary labels
 *      n       show decimal labels
 * 
 *      +       speed up
 *      =       slow down
 *
 * vector font code ported from code by jared schiffman and i from
 * the acg's internal graphics library "acu". vector font by josh nimoy.
 *
 * the integrator is my simple spring-based integrator class.
 */

import processing.pdf.*;    // comment if not exporting PDF for performance

boolean debug = false; 
boolean outputPDF = false; // using PDF library, write a sequence of pdf files
boolean showText = true;
boolean showLines = true;
boolean shadeLines = true;  // [true] to fake 3d depth 
boolean changeRotation = false;  // flag for changing rotation on 'c' key
boolean show_labels = true;  
boolean show_binary_labels = false;  
boolean show_coordinate_labels = false;  

String pdfFilename = "4D"; // name for PDF file sequence
String labels[] =        {"0","1","2","3","4","5","6","7","8","9","10","11","12","13","14","15"};
String labels_binary[] = {"0000","1000","0100","1100","0010","1010","0110","1110","0001","1001","0101","1101","0011","1011","0111","1111"};
String labels_coordinate[] = {"0,0,0,0","1,0,0,0","0,1,0,0","1,1,0,0","0,0,1,0","1,0,1,0","0,1,1,0","1,1,1,0","0,0,0,1","1,0,0,1","0,1,0,1","1,1,0,1","0,0,1,1","1,0,1,1","0,1,1,1","1,1,1,1"};

int runningTimeMax = (int) (24 * 60 * 3);  // minutes of PDF output for Chaumont film expressed as total number of frames 
int runningTimeCounter = 0;  // to keep track
int thisFill = 255; // for PDF out
int thisStroke = 255; 
int thisBackground = 0;

PFont display;   // for 4d specimen
int cornCount = 0;
float seedCorn[][] = {
  {
    -1, -1, -1, -1
  }
  , {
    -1, -1, -1, 1
  }
  , {
    -1, -1, 1, -1
  }
  , {
    -1, -1, 1, 1
  }
  , {
    -1, 1, -1, -1
  }
  , {
    -1, 1, -1, 1
  }
  , {
    -1, 1, 1, -1
  }
  , {
    -1, 1, 1, 1
  }
  , { 
    1, -1, -1, -1
  }
  , {
    1, -1, -1, 1
  }
  , {
    1, -1, 1, -1
  }
  , {
    1, -1, 1, 1
  }
  , { 
    1, 1, -1, -1
  }
  , { 
    1, 1, -1, 1
  }
  , { 
    1, 1, 1, -1
  }
  , { 
    1, 1, 1, 1
  }
};
float corn[][] = new float[66][4];
float tcorn[][] = new float[66][4];
float fcornx[] = new float[66];
float fcorny[] = new float[66];
float rawz[] = new float[66];      // added to keep track of z values
int trail[] = {
  0, 1, 3, 2, 6, 14, 10, 8, 9, 11, 3, 7, 15, 14, 12, 13, 9, 1, 5, 7, 6, 4, 12, 8, 0, 4, 5, 13, 15, 11, 10, 2, 0
};
float sin, cos;
float angle;
int a = 0, b = 0;
boolean inMotion = true;
char thisKey;   // used to keep track of keypresses
float textCoords[]; // string to keep track of what has been drawn and what has not, each member is xy



void setup() {
   
  size(854, 621, P3D);  // [854, 621] proportions matter
  // size(1708, 1242, P3D);  // [854, 621] proportions matter
  
  createMTDBT2F4D();
  String fontStub = "resources/Monaco.ttf"; // from sketch /data
  display = createFont(fontStub, 140, false);

  setAngle(0.05);   // [0.08] rotate speed

  for (int i = 1; i < trail.length; i++) {
    addPoint(seedCorn[trail[i-1]], seedCorn[trail[i]]);
  }

  setAngle(angle - .036);     // slowdown default value of sin / cos for rotation speed
  textCoords = new float[64];  // length is based on the draw loop (number of vertices)
}


protected void addPoint(float one[], float two[]) {
  corn[cornCount] = new float[4];
  System.arraycopy(one, 0, corn[cornCount], 0, 4);
  cornCount++;
  corn[cornCount] = new float[4];
  System.arraycopy(two, 0, corn[cornCount], 0, 4);
  cornCount++;
}

// rotates in 1 and 3
// cos(theta)   0    -sin(theta)
//         0    1             0
// sin(theta)   0     cos(theta)

protected void multiply(float mat1[][], float mat2[][], float out[][]) {
  for (int i = 0; i < 4; i++) {
    for (int j = 0; j < 4; j++) {
      out[i][j] = 0;
    }
  }
  for (int i = 0; i < 4; i++) {
    for (int j = 0; j < 4; j++) {
      for (int k = 0; k < 4; k++) {
        out[i][j] += mat1[i][k] * mat2[k][j];
      }
    }
  }
}

protected void transform4(float m[][], float in[], float out[]) {
  out[0] = m[0][0]*in[0] + m[0][1]*in[1] + m[0][2]*in[2] + m[0][3]*in[3];
  out[1] = m[1][0]*in[0] + m[1][1]*in[1] + m[1][2]*in[2] + m[1][3]*in[3];
  out[2] = m[2][0]*in[0] + m[2][1]*in[1] + m[2][2]*in[2] + m[2][3]*in[3];
  out[3] = m[3][0]*in[0] + m[3][1]*in[1] + m[3][2]*in[2] + m[3][3]*in[3];
}

float rotation[][] = new float[4][4]; 
protected void rotate(int a, int b) {
  for (int i = 0; i < 4; i++) {
    for (int j = 0; j < 4; j++) {
      rotation[i][j] = 0;
    }
  }
  for (int i = 0; i < 4; i++) {
    rotation[i][i] = 1;
  }
  // setAngle(noise(frameCount) * 0.08);

  rotation[a][a] =  cos;
  rotation[b][a] = -sin;
  rotation[a][b] =  sin;
  rotation[b][b] =  cos;

  multiply(ctm, rotation, newctm);

  oldctm = ctm;
  ctm = newctm;
  newctm = oldctm;
}

static float ctm[][] = new float[4][4];
static float oldctm[][] = new float[4][4];
static float newctm[][] = new float[4][4];
static {
  for (int i = 0; i < 4; i++) {
    ctm[i][i] = 1;
  }
}

float coordinate[] = new float[4];
protected void calcTransform() {
  for (int i = 0; i < cornCount; i++) {
    for (int j = 0; j < 4; j++) {
      coordinate[j] = corn[i][j];
      transform4(ctm, coordinate, tcorn[i]);

      float f = 2f / (3+tcorn[i][0]);
      float x = f * tcorn[i][1];
      float y = f * tcorn[i][2];
      float z = f * tcorn[i][3];

      float fz = z / (z + 10);
      fcornx[i] = x - x*fz;
      fcorny[i] = y - y*fz;
      rawz[i] = fz;
    }
  }
}


// static final float WIG = 1f;

void setAngle(float newAngle) {
  angle = newAngle;
  sin = (float) Math.sin(angle);
  cos = (float) Math.cos(angle);
}

public int TX(float x) {
  return (int) (width * ((x + 3.2f) / 6.4f));
}

public int TY(float y) {
  return (int) (height * ((y + 2.4f) / 4.8f));
}

void LINE(int x1, int y1, int x2, int y2) {
if ((x1 > width) || (x2 > width) ||
    (x1 < 0) || (x2 < 0) ||
    (y1 > height) || (y2 > height) ||
    (y1 < 0) || (y2 < 0)) return;

  line(x1, y1, x2, y2);
}


void draw() {

  // output PDF frames

  if (outputPDF) {
    beginRecord(PDF, "out/pdf/" + pdfFilename + "-####.pdf");
  }

  if (inMotion) {

    // change rotation after a while 
    // if ((a == b) || (Math.random() < 0.05) || (changeRotation)) {

    // change rotation only if requested
    if ((a == b) || (changeRotation)) {
      a = (int) (Math.random() * 4.0);
      b = 0;
      do {
        b = (int) (Math.random() * 4.0);
      } 
      while (a == b);
      changeRotation = false;
    }
    rotate(a, b);
  }

    background(0);
    calcTransform();

    int index = 0;

  // for (int i = 0; i < (showText ? cornCount : 64); i += 2) {
  for (int i = 0; i < 64; i += 2) {
    if (showText) {

      boolean drawThis = true;

      // check to see if drawn before
      for ( int j = 0; j < textCoords.length; j ++) {
        if (textCoords[j] == fcornx[i] + fcorny[i]) {
          drawThis = false;
        }
      }

      textCoords[i] = fcornx[i] + fcorny[i];

    // make an array of point names rather than relying on i

      if (drawThis) {
        // textFont(font[i], (48 + rawz[i] * 100)); 
        textFont(display, 12);
        // fill(128 + (rawz[i] * 512));
        // String textStub = "M";
        // String textStub = str(i/2);
        // String textStub = labels[index];
            
        String textStub;            
        textStub = labels[index];
        if (show_binary_labels) {
            textStub = labels_binary[index];
        } 
        if (show_coordinate_labels) {
            textStub = labels_coordinate[index];
        } 
        text(textStub, TX(fcornx[i]), TY(fcorny[i]));
        index++;
      }
    } 

    if (showLines) {
      // stroke(i < 64 ? 128 : 255);
      // stroke value depends on 3d Z position
      if (shadeLines) {
        stroke(128 + (rawz[i] * 512));
      } 
      else {
        stroke(thisStroke);
      }
      LINE(TX(fcornx[i]), TY(fcorny[i]), TX(fcornx[i+1]), TY(fcorny[i+1]));
    }
  }

  // stop PDF output
  if (outputPDF) {
    endRecord();
  }

  if (debug) {
    textFont(display, 12);
    String thisDisplay = "a = " + a + "\nb = " + b + "\n< = " + angle;
    text(thisDisplay, 20, 20);  // number in font[]
  }
}

void exitClean() {
  if (outputPDF) {
    endRecord();
  }
  exit();
}


void keyPressed() {
  switch (key) {

      case ' ': 
        inMotion = !inMotion; 
        break;
      case '/': 
        showLines = !showLines; 
        break;
      case '?': 
        showText = !showText; 
        break;
      case 'n': 
        show_binary_labels = false;
        show_coordinate_labels = false;
        show_labels = !show_labels; 
        break;
      case 'b': 
        show_labels = false; 
        show_coordinate_labels = false;
        show_binary_labels = !show_binary_labels; 
        break;
      case 'v': 
        show_labels = false; 
        show_binary_labels = false;
        show_coordinate_labels = !show_coordinate_labels; 
        break;

      case '1': 
        rotate(1, 0); 
        break;  // '1' x and u axes
      case '2': 
        rotate(2, 0); 
        break;  // '2' y and u axes
      case '3': 
        rotate(3, 0); 
        break;  // '3' z and u axes
    
      case '+': 
        setAngle(angle + .003); 
        break;  // faster
      case '=': 
        setAngle(angle - .003); 
        break;  // slower
    
      case 'c':   // change rotation
        changeRotation = true;    
        break;  
        
      case ESC:  // stop recording 
        exitClean();
    
      default:
        // do this
        thisKey = key;
        break;
    }    
}
