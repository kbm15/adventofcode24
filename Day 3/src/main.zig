//! By convention, main.zig is where your main function lives in the case that
//! you are building an executable. If you are making a library, the convention
//! is to delete this file and start with root.zig instead.
const std = @import("std");
const mvzr: type = @import("mvzr");

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
fn filterDonts(allocator: *std.mem.Allocator, line: []const u8) ![]const u8 {
    var healthyList = std.ArrayList(u8).init(std.heap.page_allocator);
    var it = std.mem.tokenizeSequence(u8, line, "don't()");
    var first = true;
    while (it.next()) |token| {
        if (first) {
            try healthyList.writer().print("{s}", .{token});
            first = false;
            continue;
        }
        const do_index = std.mem.indexOf(u8, token, "do()") orelse continue;
        try healthyList.writer().print("{s}", .{token[do_index + 4 ..]});
    }

    const result = try allocator.alloc(u8, healthyList.items.len);
    std.mem.copyForwards(u8, result, healthyList.items);
    return result;
}

fn findAndMultiply(line: []const u8) !i32 {
    var sum: i32 = 0;
    var it = std.mem.tokenizeSequence(u8, line, "mul");
    while (it.next()) |token| {
        if (std.mem.startsWith(u8, token, "(")) {
            const end_index = std.mem.indexOf(u8, token, ")") orelse continue;
            const content = token[1..end_index];
            var parts = std.mem.splitAny(u8, content, ",");
            var multiplicands = std.ArrayList(i32).init(std.heap.page_allocator);
            var wrongFormat = false;
            while (parts.next()) |part| {
                if (part.len < 1 or part.len > 3 or multiplicands.items.len > 2) {
                    wrongFormat = true;
                    break;
                }
                const multiplicand = try std.fmt.parseInt(i32, part, 10);
                try multiplicands.append(multiplicand);
            }
            if (wrongFormat) continue;

            sum += multiplicands.items[0] * multiplicands.items[1];
        }
    }
    return sum;
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
    var lineSum: i32 = 0;
    while (it.next()) |line| {
        lineSum += try findAndMultiply(line);
    }
    std.debug.print("Sum: {}\n", .{lineSum});

    // Part 2
    std.debug.print("Part 2\n", .{});
    var it2 = std.mem.splitSequence(u8, buffer, "\r\n");
    var lineSum2: i32 = 0;
    while (it2.next()) |line| {
        const filteredLine = try filterDonts(&allocator, line);
        defer allocator.free(filteredLine);
        lineSum2 += try findAndMultiply(filteredLine);
    }
    std.debug.print("Sum: {}\n", .{lineSum2});
}
