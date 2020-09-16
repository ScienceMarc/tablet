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
        if (!visible) { //Skip the line if it is invisible
            return;
        }
        push();
        strokeWeight(thickness);
        line(start.x, start.y, end.x, end.y);
        pop();
    }
}