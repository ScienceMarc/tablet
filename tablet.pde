import codeanticode.tablet.*;
import java.util.*;

Tablet tablet;
Event currentEvent = new Event();
List<Line> lines = new ArrayList<Line>();
List<Event> events = new ArrayList<Event>();

Tool selectedTool = Tool.PEN;

Tool toolModes[] = {Tool.MOVE, Tool.PEN, Tool.ERASER};

PImage penIcon, eraserIcon;

enum Tool {
    PEN, ERASER, MOVE;
}

void setup() {
    size(640,640);
    surface.setResizable(true);
    frameRate(120); //Framerate limit. 120 seems sufficient for smooth lines without making the list too long. May change in future...
    noCursor();
    stroke(0);
    textSize(32);
    tablet = new Tablet(this);

    penIcon = loadImage("pen.png");
    eraserIcon = loadImage("eraser.png");
}

boolean pMousePressed = false;


void draw() {
    background(255);
    selectedTool = toolModes[tablet.getPenKind() - 1];

    if (mousePressed) {
        if (!pMousePressed) { //Determines if the pen has just been pressed.
            currentEvent.start = lines.size(); //Records the size of the list before the stroke.
            currentEvent.tool = selectedTool;
        }
        pMousePressed = true;

        switch(selectedTool) {
            case PEN:
                pen();
                break;
            case ERASER:
                eraser();
                break;
        }
    }

    if (pMousePressed && !mousePressed) { //Determines if the pen has been lifted.
        currentEvent.end = lines.size(); //Records the size of the list after the stroke.
        events.add(currentEvent);
        currentEvent = new Event();
        pMousePressed = false;
    }



    drawSketch();
    UI();
}

void keyPressed() {
    if(key == 0x1A) { //^Z
        undo();
    }
}

void pen() {
    float thickness = 30 * (map(tablet.getPressure(),0,1,0.1,0.2));
    lines.add(new Line(pmouseX, pmouseY, mouseX, mouseY, thickness));
}

void eraser() { 
    for (int i = 0; i < lines.size(); i++) {
        if (!lines.get(i).visible) { //Saves time and memory, no need to erase invisible lines.
            continue;
        }

        PVector mp = new PVector((lines.get(i).start.x + lines.get(i).end.x)/2,(lines.get(i).start.y + lines.get(i).end.y)/2);
        PVector mousePos = new PVector(mouseX,mouseY);

        if (mousePos.dist(mp) < map(tablet.getPressure(),0,1,5,15)) { //Checks if the mouse is close enough to the line to be erased.
            lines.get(i).visible = false;
            currentEvent.erased.add(i);
        }
    }
}

void drawSketch() {
    for (Line l : lines) {
        l.draw();
    }
}

void UI() {

    //TODO: Dynamically change toolbar positions based on number of tools to make it easier to add tools.
    push();
    fill(180);
    rect(0,0,width,64);
    fill(200);
    if (selectedTool == Tool.PEN) {
        rect(width/2 - 64,0,64,64);
    }
    else if (selectedTool == Tool.ERASER) {
        rect(width/2,0,64,64);
    }

    image(penIcon, width/2 - 64,0,64,64);
    image(eraserIcon, width/2,0,64,64);
    pop();

    text("mode " + tablet.getPenKind(),width - (new String("mode " + tablet.getPenKind()).length())*20,54); //Displays the current pen mode.

    if (mouseY > 64) { //Checks if the cursor is below the toolbar.
        if (tablet.getPenKind() == 1) { //If using mouse, change the cursor to a HAND
            cursor(HAND);
        }
        else { //Hide the cursor for the modes 2 & 3
            noCursor();
        }

        //Draw a circular cursor
        push();
        noFill();
        stroke(150); //TODO: Change colors to give better contrast.
        if (selectedTool == Tool.PEN) {
            circle(mouseX, mouseY, 5);
        }
        else if (selectedTool == Tool.ERASER) {
            circle(mouseX, mouseY, map(tablet.getPressure(),0,1,5,15)); //TODO: The cursor size does not match the erasing radius.
        }
        pop();
    }
    else {
        cursor(ARROW);
        if (mousePressed && tablet.getPenKind() != 3) { //Mode 3 is locked to the eraser. Modes 1 & 2 can be changed.
            if (mouseX > width/2 - 64 && mouseX < width/2) {
                toolModes[tablet.getPenKind() - 1] = Tool.PEN;
            }
            else if (mouseX > width/2 && mouseX < width/2 + 64) {
                toolModes[tablet.getPenKind() - 1] = Tool.ERASER;
            }
        }
    }
}

void undo() {
    if (events.size() < 1) { //Prevents undo if there is nothing to undo.
        return;
    }
    Event event = events.get(events.size() - 1);
    if (event.tool == Tool.PEN) {
        lines.subList(event.start, event.end).clear();
    }
    else if (event.tool == Tool.ERASER) {
        for (Integer i : event.erased) {
            lines.get(i).visible = true;
        }
    }
    events.remove(events.size() - 1);
}