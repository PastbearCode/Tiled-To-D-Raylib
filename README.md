# Tiled-To-D-Raylib
Use Tiled tilemaps in Raylib-D
A version of [Tiled To D](https://github.com/PastbearCode/Tiled-To-D) made to use with [Raylib-D](https://github.com/schveiguy/raylib-d).

## How?
First download the ttdrl.d file and put it in your project, make sure you have [Raylib-D](https://github.com/schveiguy/raylib-d) in your project too.
Then, `import ttdrl;` in your main file.

This is how you use ttdrl.d:
```d 
import ttdrl;
import raylib;
import std.stdio;

void main() {
    InitWindow(800, 600, "Tilemap Viewer");
    SetTargetFPS(60);

    writeln("DEBUG: Initializing tilemap...");
    Tilemap tilemap = createTilemap("TiledToDMapJSON.tmj", "TiledToDTiles.png");

    while (!WindowShouldClose()) {
        BeginDrawing();
        ClearBackground(Colors.RAYWHITE);

        drawTilemap(tilemap, GetMouseX(), GetMouseY());

        EndDrawing();
    }

    foreach (tile; tilemap.tileset) {
        UnloadTexture(tile);
    }

    CloseWindow();
}

```
