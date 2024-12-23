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

fn getHorizontalFlat(allocator: *std.mem.Allocator, lines: std.ArrayList([]const u8)) ![]const u8 {
    var horizontalList = std.ArrayList(u8).init(std.heap.page_allocator);
    defer horizontalList.deinit();

    for (lines.items) |line| {
        try horizontalList.writer().print("{s} ", .{line});
    }

    const horizontalFlat = try allocator.alloc(u8, horizontalList.items.len);
    std.mem.copyForwards(u8, horizontalFlat, horizontalList.items);

    return horizontalFlat;
}

fn getVerticalFlat(allocator: *std.mem.Allocator, lines: std.ArrayList([]const u8)) ![]const u8 {
    const line_length = lines.items[0].len;
    var verticalList = std.ArrayList(u8).init(std.heap.page_allocator);
    defer verticalList.deinit();

    for (0..line_length) |i| {
        for (lines.items) |line| {
            if (i < line.len) {
                try verticalList.append(line[i]);
            }
        }
        try verticalList.append(32);
    }

    const verticalFlat = try allocator.alloc(u8, verticalList.items.len);
    std.mem.copyForwards(u8, verticalFlat, verticalList.items);

    return verticalFlat;
}

fn getDiagonalFlat(allocator: *std.mem.Allocator, lines: std.ArrayList([]const u8)) ![]const u8 {
    const line_length = lines.items[0].len;
    const line_count = lines.items.len;

    var diagonalList = std.ArrayList(u8).init(std.heap.page_allocator);
    defer diagonalList.deinit();

    for (0..line_length - 2) |i| {
        for (0..line_count) |j| {
            if (i + j < line_length) {
                try diagonalList.append(lines.items[j][i + j]);
            } else {
                break;
            }
        }
        try diagonalList.append(32);
    }

    for (1..line_length - 2) |i| {
        for (0..line_count - 1) |j| {
            if (i + j < line_length) {
                try diagonalList.append(lines.items[line_count - j - 1][line_length - i - j - 1]);
            } else {
                break;
            }
        }
        try diagonalList.append(32);
    }

    const diagonalFlat = try allocator.alloc(u8, diagonalList.items.len);
    std.mem.copyForwards(u8, diagonalFlat, diagonalList.items);

    return diagonalFlat;
}

fn getDiagonalFlat2(allocator: *std.mem.Allocator, lines: std.ArrayList([]const u8)) ![]const u8 {
    const line_length = lines.items[0].len;
    const line_count = lines.items.len;

    var diagonalList = std.ArrayList(u8).init(std.heap.page_allocator);
    defer diagonalList.deinit();

    for (0..line_length - 2) |i| {
        for (0..line_count) |j| {
            if (i + j < line_length) {
                try diagonalList.append(lines.items[j][line_length - i - j - 1]);
            } else {
                break;
            }
        }
        try diagonalList.append(32);
    }
    for (1..line_length - 2) |i| {
        for (0..line_count - 1) |j| {
            if (i + j < line_length) {
                try diagonalList.append(lines.items[line_count - j - 1][i + j]);
            } else {
                break;
            }
        }
        try diagonalList.append(32);
    }
    const diagonalFlat = try allocator.alloc(u8, diagonalList.items.len);
    std.mem.copyForwards(u8, diagonalFlat, diagonalList.items);

    return diagonalFlat;
}

fn countToken(buffer: []const u8, token: []const u8) usize {
    var count: usize = 0;
    var i: usize = 0;

    while (i <= buffer.len - token.len) {
        if (std.mem.eql(u8, buffer[i .. i + token.len], token)) {
            count += 1;
            i += token.len;
        } else {
            i += 1;
        }
    }

    return count;
}

fn countXMas(lines: std.ArrayList([]const u8)) usize {
    const line_length = lines.items[0].len;
    const line_count = lines.items.len;
    var count: usize = 0;

    for (0..line_count - 2) |i| {
        for (0..line_length - 2) |j| {
            const diag1 = [3]u8{ lines.items[i][j], lines.items[i + 1][j + 1], lines.items[i + 2][j + 2] };
            const diag2 = [3]u8{ lines.items[i][j + 2], lines.items[i + 1][j + 1], lines.items[i + 2][j] };

            if ((std.mem.eql(u8, &diag1, "MAS") or std.mem.eql(u8, &diag1, "SAM")) and
                (std.mem.eql(u8, &diag2, "MAS") or std.mem.eql(u8, &diag2, "SAM")))
            {
                count += 1;
            }
        }
    }

    return count;
}

pub fn main() !void {
    std.debug.print("Fourth day of Advent of Code 2024!\n", .{});

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

    var flatList = std.ArrayList([]const u8).init(std.heap.page_allocator);

    const horizontal = try getHorizontalFlat(&allocator, lines);
    defer allocator.free(horizontal);
    try flatList.append(horizontal);

    const vertical = try getVerticalFlat(&allocator, lines);
    defer allocator.free(vertical);
    try flatList.append(vertical);

    const diagonal = try getDiagonalFlat(&allocator, lines);
    defer allocator.free(diagonal);
    try flatList.append(diagonal);

    const diagonal2 = try getDiagonalFlat2(&allocator, lines);
    defer allocator.free(diagonal2);
    try flatList.append(diagonal2);

    var count: usize = 0;
    for (flatList.items) |flat| {
        count += countToken(flat, "XMAS");
        count += countToken(flat, "SAMX");
    }
    std.debug.print("Count: {}\n", .{count});

    // Part 2
    std.debug.print("Part 2\n", .{});

    count = countXMas(lines);

    std.debug.print("Count: {}\n", .{count});
}
