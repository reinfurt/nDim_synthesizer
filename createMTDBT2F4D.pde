PFont font[];     // array of references to fonts

String fontDataFolder = "data/" + "mtdbt2f-4d --steps 70 --exit 700 --weight 5 200 --slant -.2 .2 --super .5 .8 --pen 0 .333 3 0 720"; // folder name that contains MTDBT2F4D range
String fontnames[];  // original source names used for naming pdf, png


boolean createMTDBT2F4Dbusy = true; // flag used when generating MTDBT2F4Ds

int fontSize = 72;  // [80] points [72]
int fontLength = 0;  // length of font[] (computed when filled)
int thisFont = 0; // pointer to font[] of currently selected
int fontRangeStart = 0; // pointer to font[], range min
int fontRangeEnd = 993; // pointer to font[], range max
int fontLoadLimit = 80; // maximum fonts to try in createMTDBT2F4D()
int fontRangeDirection = 1; // only two values, 1 or -1
int fontRangeCoarseness = 10; // number of fonts to skip in range


void createMTDBT2F4D()
{

  // createFont() works either from data folder or from installed fonts
  // renders with installed fonts if in regular JAVA2D mode
  // the fonts installed in sketch data folder make it possible to export standalone app
  // but the performance seems to suffer a little. also requires appending extension .ttf
  // biggest issue is that redundantly named fonts create referencing problems

  if ( fontRangeEnd - fontRangeStart  > fontLoadLimit ) {
    fontLoadLimit = fontRangeEnd - fontRangeStart;
  }

  font = new PFont[fontLoadLimit];
  fontnames = new String[fontLoadLimit];
  fontLength = 0; // reset

  for ( int i = 0; i < fontLoadLimit; i+=fontRangeCoarseness ) {  
    String fontStub = fontDataFolder + "/mtdbt2f4d-" + i + ".ttf"; // from sketch /data

    if ( createFont(fontStub, fontSize, true) != null ) {
      font[fontLength] = createFont(fontStub, fontSize, true);
      fontnames[fontLength] = "mtdbt2f4d-" + i;
      println("/mtdbt2f4d-" + i + ".ttf" + " ** OK **");
      fontLength++;
    }
  }

  // in range? catch errors

  if ( fontRangeEnd - fontRangeStart > fontLength ) {
    fontRangeEnd = fontLength - 1;
  }

  println("** init complete -- " + fontLength + " / " + font.length + " **");
  createMTDBT2F4Dbusy = false;
}
