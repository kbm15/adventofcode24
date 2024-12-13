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

fn popOne(allocator: *std.mem.Allocator, line: []const u8, index: usize) ![]const u8 {
    var numberList = std.ArrayList(i32).init(std.heap.page_allocator);
    defer numberList.deinit();
    var it = std.mem.splitSequence(u8, line, " ");
    var j: usize = 0;
    while (it.next()) |number| {
        const num = try std.fmt.parseInt(i32, number, 10);
        if (j != index) {
            try numberList.append(num);
        }
        j += 1;
    }
    var charList = std.ArrayList(u8).init(std.heap.page_allocator);
    var first = true;
    for (numberList.items) |item| {
        if (first) {
            try charList.writer().print("{}", .{item});
            first = false;
        } else {
            try charList.writer().print(" {}", .{item});
        }
    }
    const result = try allocator.alloc(u8, charList.items.len);
    std.mem.copyForwards(u8, result, charList.items);
    return result;
}

fn isItSafe(line: []const u8) !bool {
    var ascending = false;
    var descending = false;
    var danger = false;
    var previous: i32 = 0;
    var first = true;

    var it = std.mem.splitSequence(u8, line, " ");
    while (it.next()) |number| {
        const num = try std.fmt.parseInt(i32, number, 10);
        if (first) {
            previous = num;
            first = false;
        } else {
            const diff = if (num > previous) num - previous else previous - num;
            if (diff < 1 or diff > 3) {
                danger = true;
            }
            if (num > previous) {
                ascending = true;
            } else if (num < previous) {
                descending = true;
            }
            previous = num;
        }
    }
    return !danger and (ascending != descending);
}

pub fn main() !void {
    std.debug.print("Second day of Advent of Code 2024!\n", .{});

    const filename = "list.txt";
    //const filename = "test.txt";
    var allocator = std.heap.page_allocator;

    const buffer = try readFile(&allocator, filename);
    defer allocator.free(buffer);

    var lines = std.ArrayList([]const u8).init(allocator);
    defer lines.deinit();

    var it = std.mem.splitSequence(u8, buffer, "\r\n");
    while (it.next()) |line| {
        try lines.append(line);
    }

    std.debug.print("Number of lines: {}\n", .{lines.items.len});

    var safe_count: i32 = 0;

    for (lines.items) |line| {
        if (try isItSafe(line)) {
            safe_count += 1;
        }
    }

    std.debug.print("Safe count: {}\n", .{safe_count});

    std.debug.print("Second part\n", .{});

    safe_count = 0;
    for (lines.items) |line| {
        if (try isItSafe(line)) {
            safe_count += 1;
        } else {
            it = std.mem.splitSequence(u8, line, " ");
            var j: usize = 0;
            while (it.next() != null) {
                const filteredLine = try popOne(&allocator, line, j);
                defer allocator.free(filteredLine);
                if (try isItSafe(filteredLine)) {
                    safe_count += 1;
                    break;
                }
                j += 1;
            }
        }
    }
    std.debug.print("Safest count: {}\n", .{safe_count});
}
