module ttdrl;

import raylib;
import std.json;
import std.file;
import std.stdio;

struct Tile {
    int id;
}

struct Layer {
    string name;
    Tile[] tiles;
}

struct Object {
    string name;
    float x;
    float y;
    float width;
    float height;
    string type;
}

struct ObjectLayer {
    string name;
    Object[] objects;
}

struct Tilemap {
    int width;
    int height;
    int tileWidth;
    int tileHeight;
    Texture2D[] tileset;
    Layer[] layers;
    ObjectLayer[] objectLayers;
}

Texture2D[] splitTileset(string path, int tileWidth, int tileHeight) {
    Texture2D[] output;
    //writeln("DEBUG: Loading tileset image from path: ", path);

    Image tilesetImage = LoadImage(path.ptr);
    if (tilesetImage.data is null) {
        //writeln("ERROR: Failed to load tileset image.");
        return output;
    }

    //writeln("DEBUG: Tileset image dimensions: ", tilesetImage.width, "x", tilesetImage.height);

    if (tilesetImage.width % tileWidth != 0 || tilesetImage.height % tileHeight != 0) {
        //writeln("ERROR: Tileset dimensions are not divisible by tile size!");
        //writeln("       Tile Width: ", tileWidth, ", Tile Height: ", tileHeight);
        //writeln("       Image Width: ", tilesetImage.width, ", Image Height: ", tilesetImage.height);
        UnloadImage(tilesetImage);
        return output;
    }

    int tilesPerRow = tilesetImage.width / tileWidth;
    int tilesPerColumn = tilesetImage.height / tileHeight;

    //writeln("DEBUG: Tiles per row: ", tilesPerRow, ", Tiles per column: ", tilesPerColumn);

    for (int y = 0; y < tilesPerColumn; ++y) {
        for (int x = 0; x < tilesPerRow; ++x) {
            Rectangle sourceRect = Rectangle(
                x * tileWidth,
                y * tileHeight,
                tileWidth,
                tileHeight
            );

            //writeln("DEBUG: Extracting tile at (", x, ", ", y, "), Rectangle: ", sourceRect);

            Image tileImage = ImageFromImage(tilesetImage, sourceRect);
            if (tileImage.data is null) {
                //writeln("ERROR: Failed to extract tile image.");
                continue;
            }

            Texture2D tileTexture = LoadTextureFromImage(tileImage);
            UnloadImage(tileImage);

            if (tileTexture.id == 0) {
                //writeln("ERROR: Failed to load tile texture.");
                continue;
            }

            output ~= tileTexture;
        }
    }

    UnloadImage(tilesetImage);
    //writeln("DEBUG: Finished splitting tileset. Total tiles: ", output.length);

    return output;
}

Tilemap createTilemap(string filePathToJson, string filePathToTileset) {
    auto jsonData = readText(filePathToJson);
    auto json = parseJSON(jsonData);

    Tilemap map;
    map.width = json["width"].get!int();
    map.height = json["height"].get!int();
    map.tileWidth = json["tilewidth"].get!int();
    map.tileHeight = json["tileheight"].get!int();

    //writeln("DEBUG: Tilemap dimensions: ", map.width, "x", map.height);
    //writeln("DEBUG: Tile size from JSON: ", map.tileWidth, "x", map.tileHeight);

    map.tileset = splitTileset(filePathToTileset, map.tileWidth, map.tileHeight);
    //writeln("DEBUG: Tileset contains ", map.tileset.length, " tiles.");

    foreach (layer; json["layers"].array) {
        if (layer["type"].str == "tilelayer") {
            Layer newLayer;
            newLayer.name = layer["name"].str;

            foreach (tileId; layer["data"].array) {
                newLayer.tiles ~= Tile(tileId.get!int());
            }

            map.layers ~= newLayer;
        } else if (layer["type"].str == "objectgroup") {
            ObjectLayer newObjectLayer;
            newObjectLayer.name = layer["name"].str;

            foreach (object; layer["objects"].array) {
                Object newObject;

                try {
                    newObject.name = object["name"].get!string();
                    newObject.x = object["x"].get!float();
                    newObject.y = object["y"].get!float();
                    newObject.width = object["width"].get!float();
                    newObject.height = object["height"].get!float();
                    newObject.type = object["type"].get!string();
                } catch (Exception e) {
                    //writeln("ERROR: Malformed object data: ", e.msg);
                    continue;
                }

                newObjectLayer.objects ~= newObject;
            }

            map.objectLayers ~= newObjectLayer;
        }
    }

    return map;
}

void drawTilemap(Tilemap map, int ox = 0, int oy = 0) {
    //writeln("DEBUG: Rendering tilemap at offset (", ox, ", ", oy, ")");
    //writeln("DEBUG: Map dimensions: ", map.width, "x", map.height);
    //writeln("DEBUG: Tile size: ", map.tileWidth, "x", map.tileHeight);

    foreach (layer; map.layers) {
        //writeln("DEBUG: Rendering layer: ", layer.name);
        for (int y = 0; y < map.height; ++y) {
            for (int x = 0; x < map.width; ++x) {
                int tileIndex = layer.tiles[y * map.width + x].id - 1;

                if (tileIndex < 0 || tileIndex >= map.tileset.length) {
                    //writeln("WARNING: Skipping invalid tile index: ", tileIndex);
                    continue;
                }

                DrawTexture(
                    map.tileset[tileIndex],
                    ox + x * map.tileWidth,
                    oy + y * map.tileHeight,
                    Colors.WHITE
                );
                //writeln("DEBUG: Tile ", tileIndex, " drawn at (", x, ", ", y, ")");
            }
        }
    }
}
