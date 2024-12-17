//! By convention, main.zig is where your main function lives in the case that
//! you are building an executable. If you are making a library, the convention
//! is to delete this file and start with root.zig instead.
const std = @import("std");

fn readFile(allocator: *std.mem.Allocator, filename: []const u8) ![]u8 {
    const file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    const file_size = (try file.stat()).size;
    const buffer = try allocator.alloc(u8, file_size);

    const bytesRead = try file.reader().readAll(buffer);
    if (bytesRead != buffer.len) {
        return error.UnexpectedEOF;
    }
    return buffer;
}

fn walk(allocator: *std.mem.Allocator, coordinates: []usize, direction: u8, map: std.ArrayList([]const u8)) ![]usize {
    var found = false;
    var tempCoordinates: []usize = try allocator.alloc(usize, 2);
    while (!found) {
        switch (direction) {
            '^' => {
                if (coordinates[0] == 0) break;
                tempCoordinates[0] = coordinates[0] - 1;
            },
            'v' => {
                if (coordinates[0] == map.items.len - 1) break;
                tempCoordinates[0] = coordinates[0] + 1;
            },
            '<' => {
                if (coordinates[1] == 0) break;
                tempCoordinates[1] = coordinates[1] - 1;
            },
            '>' => {
                if (coordinates[1] == map.items[coordinates[0]].len - 1) break;
                tempCoordinates[1] = coordinates[1] + 1;
            },
            else => return error.InvalidDirection,
        }

        if (map.items[tempCoordinates[0]][tempCoordinates[1]] == '#') {
            found = true;
        } else {
            coordinates[0] = tempCoordinates[0];
            coordinates[1] = tempCoordinates[1];
        }
    }

    const finalCoordinates = try allocator.alloc(usize, 2);
    std.mem.copyForwards(usize, finalCoordinates, coordinates);

    return finalCoordinates;
}

fn writeJourney(allocator: *std.mem.Allocator, startCoordinates: []usize, finalCoordinates: []usize, map: std.ArrayList([]const u8)) !usize {
    var walkedDistance: usize = 0;
    var tempCoordinates: []usize = try allocator.alloc(usize, 2);
    std.mem.copyForwards(usize, tempCoordinates, startCoordinates);

    while (tempCoordinates[0] != finalCoordinates[0] or tempCoordinates[1] != finalCoordinates[1]) {
        if (tempCoordinates[0] < finalCoordinates[0]) {
            std.debug.print("Walking south\n", .{});
            tempCoordinates[0] += 1;
        } else if (tempCoordinates[0] > finalCoordinates[0]) {
            std.debug.print("Walking north\n", .{});
            tempCoordinates[0] -= 1;
        } else if (tempCoordinates[1] < finalCoordinates[1]) {
            std.debug.print("Walking east\n", .{});
            tempCoordinates[1] += 1;
        } else if (tempCoordinates[1] > finalCoordinates[1]) {
            std.debug.print("Walking west\n", .{});
            tempCoordinates[1] -= 1;
        }

        const currentChar = map.items[tempCoordinates[0]][tempCoordinates[1]];
        switch (currentChar) {
            '.' => {
                map.items[tempCoordinates[0]][tempCoordinates[1]] = 'X';
                walkedDistance += 1;
            },
            'X' => {},
            else => return error.InvalidMapCharacter,
        }
    }

    return walkedDistance;
}

pub fn main() !void {
    std.debug.print("Sixth day of Advent of Code 2024!\n", .{});

    //const filename = "list.txt";
    const filename = "test.txt";
    var allocator = std.heap.page_allocator;

    const buffer = try readFile(&allocator, filename);
    defer allocator.free(buffer);

    var lines = std.ArrayList(u8).init(allocator);
    defer lines.deinit();

    var it = std.mem.splitSequence(u8, buffer, "\r\n");

    var j: usize = 0;
    var startCoordinates: []usize = try allocator.alloc(usize, 2);
    while (it.next()) |line| {
        try lines.append(line);
        if (std.mem.indexOf(u8, line, "^") != null) {
            startCoordinates[0] = j;
            startCoordinates[1] = std.mem.indexOf(u8, line, "^").?;
            std.debug.print("Found '^' at coordinates: ({d}, {d})\n", .{ startCoordinates[0], startCoordinates[1] });
        }
        j += 1;
    }

    var puzzleSolved = false;
    var walkedDistance: usize = 0;
    while (!puzzleSolved) {
        const finalCoordinates = try walk(&allocator, startCoordinates, lines.items[startCoordinates[0]][startCoordinates[1]], lines);
        std.debug.print("Final coordinates: ({d}, {d})\n", .{ finalCoordinates[0], finalCoordinates[1] });
        walkedDistance += try writeJourney(&allocator, startCoordinates, finalCoordinates, lines);

        if (finalCoordinates[0] == 0 or finalCoordinates[1] == 0 or finalCoordinates[0] == lines.items.len - 1 or finalCoordinates[1] == lines.items[finalCoordinates[0]].len - 1) {
            puzzleSolved = true;
        }
    }

    std.debug.print("Walked distance: {}\n", .{walkedDistance});
}
