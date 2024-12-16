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

fn checkValidUpdate(rules: std.ArrayList([]const u8), updates: []const u8) !bool {
    var it = std.mem.splitSequence(u8, updates, ",");
    var updatesList = std.ArrayList(i32).init(std.heap.page_allocator);
    defer updatesList.deinit();
    var rulesList = std.ArrayList(i32).init(std.heap.page_allocator);
    defer rulesList.deinit();

    while (it.next()) |update| {
        const updateInt = try std.fmt.parseInt(i32, update, 10);
        for (rules.items) |rule| {
            var ruleTokens = std.mem.splitSequence(u8, rule, "|");
            const rule1 = try std.fmt.parseInt(i32, ruleTokens.next().?, 10);
            if (rule1 == updateInt) {
                const rule2 = try std.fmt.parseInt(i32, ruleTokens.next().?, 10);
                if (std.mem.indexOfScalar(i32, updatesList.items, rule2) != null) {
                    return false;
                } else {
                    try rulesList.append(rule2);
                }
            }
        }
        try updatesList.append(updateInt);
    }
    return true;
}

fn fixInvalidUpdate(allocator: *std.mem.Allocator, rules: std.ArrayList([]const u8), updates: []const u8) ![]const u8 {
    var it = std.mem.splitSequence(u8, updates, ",");
    var updatesList = std.ArrayList(i32).init(std.heap.page_allocator);
    defer updatesList.deinit();
    var rulesList = std.ArrayList(i32).init(std.heap.page_allocator);
    defer rulesList.deinit();
    var bufferIndexList = std.ArrayList(usize).init(std.heap.page_allocator);
    defer bufferIndexList.deinit();
    var bufferValueList = std.ArrayList(i32).init(std.heap.page_allocator);
    defer bufferValueList.deinit();

    while (it.next()) |update| {
        const updateInt = try std.fmt.parseInt(i32, update, 10);
        for (rules.items) |rule| {
            var ruleTokens = std.mem.splitSequence(u8, rule, "|");
            const rule1 = try std.fmt.parseInt(i32, ruleTokens.next().?, 10);
            if (rule1 == updateInt) {
                const rule2 = try std.fmt.parseInt(i32, ruleTokens.next().?, 10);
                const index = std.mem.indexOfScalar(i32, updatesList.items, rule2);
                if (index != null) {
                    try bufferIndexList.append(index.?);
                    try bufferValueList.append(rule2);
                }
                try rulesList.append(rule2);
            }
        }
        try updatesList.append(updateInt);
        if (bufferIndexList.items.len > 0) {
            const updatesListLen = updatesList.items.len - 1;
            for (0..updatesListLen) |i| {
                const indexRemoval = std.mem.indexOfScalar(usize, bufferIndexList.items, updatesListLen - i - 1);
                if (indexRemoval != null) {
                    _ = updatesList.orderedRemove(updatesListLen - i - 1);
                }
            }
            for (0..updatesListLen) |i| {
                const insertIndex = std.mem.indexOfScalar(usize, bufferIndexList.items, i);
                try updatesList.append(bufferValueList.items[insertIndex orelse continue]);
            }
            bufferIndexList.clearAndFree();
            bufferValueList.clearAndFree();
        }
    }

    var charList = std.ArrayList(u8).init(std.heap.page_allocator);
    var first = true;
    for (updatesList.items) |item| {
        if (first) {
            try charList.writer().print("{d}", .{item});
            first = false;
        } else {
            try charList.writer().print(",{d}", .{item});
        }
    }
    const result = try allocator.alloc(u8, charList.items.len);
    std.mem.copyForwards(u8, result, charList.items);
    return result;
}

fn middleNumber(line: []const u8) !i32 {
    var it = std.mem.splitSequence(u8, line, ",");
    var numberList = std.ArrayList(i32).init(std.heap.page_allocator);
    defer numberList.deinit();
    while (it.next()) |number| {
        const num = try std.fmt.parseInt(i32, number, 10);
        try numberList.append(num);
    }
    if (numberList.items.len % 2 == 0) {
        return numberList.items[numberList.items.len / 2];
    } else {
        return numberList.items[(numberList.items.len - 1) / 2];
    }
}

pub fn main() !void {
    std.debug.print("Fifth day of Advent of Code 2024!\n", .{});

    const filename = "list.txt";
    //const filename = "test.txt";
    var allocator = std.heap.page_allocator;

    const buffer = try readFile(&allocator, filename);
    defer allocator.free(buffer);

    const delimiter = "\r\n\r\n";
    const index = std.mem.indexOf(u8, buffer, delimiter);
    if (index == null) {
        return error.InvalidData;
    }

    //Read rules to list
    const rules = try allocator.alloc(u8, index.?);
    std.mem.copyForwards(u8, rules, buffer[0..index.?]);
    defer allocator.free(rules);

    var rulesList = std.ArrayList([]const u8).init(allocator);
    defer rulesList.deinit();

    var it = std.mem.splitSequence(u8, rules, "\r\n");
    while (it.next()) |line| {
        try rulesList.append(line);
    }

    //Read updates to list
    const updates = try allocator.alloc(u8, buffer.len - (index.? + 4));
    std.mem.copyForwards(u8, updates, buffer[(index.? + 4)..]);
    defer allocator.free(updates);

    var updatesList = std.ArrayList([]const u8).init(allocator);
    defer updatesList.deinit();

    var invalidUpdates = std.ArrayList([]const u8).init(allocator);
    defer invalidUpdates.deinit();

    it = std.mem.splitSequence(u8, updates, "\r\n");
    while (it.next()) |line| {
        if (try checkValidUpdate(rulesList, line)) {
            try updatesList.append(line);
        } else {
            try invalidUpdates.append(line);
        }
    }

    var count: i32 = 0;
    for (updatesList.items) |update| {
        count += try middleNumber(update);
    }
    std.debug.print("Count: {d}\n", .{count});

    //Part 2
    std.debug.print("Part 2\n", .{});
    var count2: i32 = 0;
    for (invalidUpdates.items) |update| {
        const fixedUpdate = try fixInvalidUpdate(&allocator, rulesList, update);
        defer allocator.free(fixedUpdate);
        std.debug.print("Wrong update: {s}\n", .{update});
        std.debug.print("Fixed update: {s}\n", .{fixedUpdate});
        count2 += try middleNumber(fixedUpdate);
    }
    std.debug.print("Count: {d}\n", .{count2});
}
