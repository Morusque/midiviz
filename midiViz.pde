
import java.util.Vector;
import javax.sound.midi.*;
import java.awt.Color;

int frameNb=0;
int currentTick=-150;

float speed = 15;
float screenTickSize = 250;

ArrayList<Note> notes = new ArrayList<Note>();
Note[] startedNotes = new Note[128];

int nbChannels=0;

boolean recordOutput = false;

String[] filesUrl;
boolean useFileHues = true;// if false hue=channel and if true hue=file
color[] filesHues;

void setup() {
  size(800, 600);
  colorMode(HSB);
  frameRate(25);
  filesUrl = new String[2];
  filesUrl[0] = "testmid.mid";
  filesUrl[1] = "beat.mid";
  filesHues = new color[2];
  filesHues[0] = 0x50;
  filesHues[1] = 0x0;
  try {
    for (int fileId = 0; fileId < filesUrl.length; fileId++) {
      File midiFile = new File(dataPath(filesUrl[fileId]));
      println("loading the file");
      Sequencer sequencer = MidiSystem.getSequencer();
      sequencer.open();
      println("getting sequence");
      Sequence sequence = MidiSystem.getSequence(midiFile);
      Track[] tracks = sequence.getTracks();
      nbChannels = tracks.length;
      for (int i=0; i<tracks.length; i++) {
        println("analyzing track "+i+" of "+nbChannels);
        println(tracks[i].size ()+ " events");
        for (int j=0; j<tracks[i].size (); j++) {
          MidiEvent event = tracks[i].get(j);
          byte[] bytes = event.getMessage().getMessage();
          if (event.getMessage().getStatus()==0x90 || event.getMessage().getStatus()==0x80) {// if the status is one from a note on or off
            if (bytes.length==3) {// if it's (probably) a note message (do we still need this ?)
              if (bytes[2]!=0&&event.getMessage().getStatus()==0x90) {// if it's a note on (do we still need to check the second byte ?)
                Note thisNote = new Note((int)bytes[1], i, event.getTick(), (int)bytes[2], fileId);
                if (startedNotes[bytes[1]]!=null) {
                  startedNotes[bytes[1]].setNoteOff(event.getTick());
                  startedNotes[bytes[1]]=null;
                }
                startedNotes[bytes[1]]=thisNote;
                notes.add(thisNote);
              } else {// if it's a note off
                if (startedNotes[bytes[1]]!=null) {
                  startedNotes[bytes[1]].setNoteOff(event.getTick());
                  startedNotes[bytes[1]]=null;
                }
              }
            }
          }
        }
      }
    }
  }
  catch(Exception e) {
    println(e);
  }
  println(notes.size()+" notes");
  /*
  for (Note note : notes) {
   println("note : "+note.startTick+" "+note.stopTick+" | "+(note.stopTick-note.startTick)+" "+note.note+" "+note.channel+" "+note.velo);
   }
   */
}

void draw() {
  background(0);
  for (Note note : notes) {
    if ((float)(note.startTick-currentTick)/screenTickSize*height<height&&(float)(note.stopTick-currentTick)/screenTickSize*height>0) {
      if (note.stopTick!=-1) {// ignore unfinished notes
        float hue = floor((float)note.channel*0x100/nbChannels);
        if (useFileHues) hue = filesHues[note.fileId];
        fill(hue, 0xFF, floor((float)note.velo*0x100/128.0f));
        stroke(hue, 0xFF, 0xFF);
        rect(floor((float)note.note*width/128.0f), floor((float)(note.startTick-currentTick)/screenTickSize*height), floor((float)width/128.0f), floor((float)(note.stopTick-note.startTick)/screenTickSize*height));
      }
    }
  }
  currentTick+=speed;
  if (recordOutput) save(dataPath("result/"+nf(frameNb, 6)+".png"));
  frameNb++;
}

class Note {
  long startTick=-1;
  long stopTick=-1;
  int note=-1;
  int channel=-1;
  int velo=0;
  int fileId=-1;
  Note (int note, int channel, long startTick, int velo, int fileId) {
    this.note=note;
    this.channel=channel;
    this.startTick=startTick;
    this.velo=velo;
    this.fileId=fileId;
  }
  void setNoteOff (long stopTick) {
    this.stopTick=stopTick;
  }
}
