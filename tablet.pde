import codeanticode.tablet.*;
import java.util.*;

Tablet tablet;
Event currentEvent = new Event();
List<Line> lines = new ArrayList<Line>();
List<Event> events = new ArrayList<Event>();
Tool selectedTool = Tool.PEN;

PImage penIcon, eraserIcon;

enum Tool {
    PEN, ERASER;
}

class Line {
    PVector start, end;
    float thickness;
    boolean visible;
    Line(int px, int py, int x, int y, float thickness) {
        visible = true;
        start = new PVector(px, py);
        end = new PVector(x,y);
        this.thickness = thickness;
    }
    void draw() {
        if (!visible) {
            return;
        }
        push();
        strokeWeight(thickness);
        line(start.x, start.y, end.x, end.y);
        pop();
    }
}

class Event {
    int start, end;
    Tool tool;
    List<Integer> erased;
    Event() {
        erased = new ArrayList<Integer>();
    }
}

void setup() {
    size(640,640);
    surface.setResizable(true);
    frameRate(120);
    noCursor();
    stroke(0);
    tablet = new Tablet(this);

    penIcon = loadImage("pen.png");
    eraserIcon = loadImage("eraser.png");
}

boolean pMousePressed = false;


void draw() {
    background(255);
    selectedTool = tablet.getPenKind() == 3 ? Tool.ERASER : Tool.PEN;

    if (mousePressed) {
        if (!pMousePressed) {
            currentEvent.start = lines.size();
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

    if (pMousePressed && !mousePressed) {
        currentEvent.end = lines.size();
        events.add(currentEvent);
        currentEvent = new Event();
        pMousePressed = false;
    }



    drawSketch();
    drawUI();
}

void keyPressed() {
    if(key == 0x1A) {
        undo();
    }
}

void pen() {
    float thickness = 30 * (map(tablet.getPressure(),0,1,0.1,0.2));
    lines.add(new Line(pmouseX, pmouseY, mouseX, mouseY, thickness));
}

void eraser() { 
    for (int i = 0; i < lines.size(); i++) {
        if (!lines.get(i).visible) {
            continue;
        }

        PVector mp = new PVector((lines.get(i).start.x + lines.get(i).end.x)/2,(lines.get(i).start.y + lines.get(i).end.y)/2);
        PVector mousePos = new PVector(mouseX,mouseY);

        if (mousePos.dist(mp) < map(tablet.getPressure(),0,1,5,15)) {
            lines.get(i).visible = false;
            currentEvent.erased.add(i);
        }
    }
}

void drawSketch() {
    for (Line l : lines) {
        l.draw();
    }/*
    for (Event e : events) {
        print(e.start + " " + e.end + " " + e.tool);
        for (int i = 0; i < e.erased.size(); i++) {
            print(e.erased.get(i) + " ");
        }
        print("\n");
    }*/
}
void drawUI() {

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
    if (mouseY > 64 && tablet.getPenKind() > 1) {
        noCursor();
        push();
        noFill();
        stroke(150);
        if (selectedTool == Tool.PEN) {
            circle(mouseX, mouseY, 5);
        }
        else if (selectedTool == Tool.ERASER) {
            circle(mouseX, mouseY, map(tablet.getPressure(),0,1,5,15));
        }
        pop();
    }
    else {
        cursor(ARROW);
    }
}

void undo() {
    if (events.size() < 1) {
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