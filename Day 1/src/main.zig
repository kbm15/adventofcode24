const std = @import("std");

pub fn main() !void {
    std.debug.print("First day of Advent of Code 2024!\n", .{});

    const filename = "list.txt";

    const file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    var allocator = std.heap.page_allocator;

    const file_size = (try file.stat()).size;
    const buffer = try allocator.alloc(u8, file_size);
    defer allocator.free(buffer);

    const bytesRead = try file.reader().readAll(buffer);
    if (bytesRead != buffer.len) {
        return error.UnexpectedEOF;
    }

    var lines = std.ArrayList([]const u8).init(allocator);
    defer lines.deinit();

    var it = std.mem.splitSequence(u8, buffer, "\r\n");
    while (it.next()) |line| {
        try lines.append(line);
    }

    std.debug.print("Number of lines: {}\n", .{lines.items.len});

    var numbers = std.ArrayList(u32).init(allocator);
    defer numbers.deinit();

    for (lines.items) |line| {
        //std.debug.print("Processing line: {s}\n", .{line});
        it = std.mem.splitSequence(u8, line, "   ");
        while (it.next()) |number| {
            //std.debug.print("Processing number: {s}\n", .{number});
            const num = try std.fmt.parseInt(u32, number, 10);
            try numbers.append(num);
        }
    }

    std.debug.print("Total numbers parsed: {}\n", .{numbers.items.len});

    var list1 = try allocator.alloc(u32, numbers.items.len / 2);
    defer allocator.free(list1);
    var list2 = try allocator.alloc(u32, numbers.items.len / 2);
    defer allocator.free(list2);

    var list1_index: usize = 0;
    var list2_index: usize = 0;

    for (0.., numbers.items) |index, num| {
        if (index % 2 == 0) {
            list1[list1_index] = num;
            list1_index += 1;
        } else {
            list2[list2_index] = num;
            list2_index += 1;
        }
    }

    std.debug.print("List 1 before: {any}\n", .{list1[0..@min(5, list1_index)]});
    std.mem.sort(u32, list1, {}, comptime std.sort.asc(u32));
    std.debug.print("List 1 after: {any}\n", .{list1[0..@min(5, list1_index)]});

    std.debug.print("List 2 before: {any}\n", .{list2[0..@min(5, list2_index)]});
    std.mem.sort(u32, list2, {}, comptime std.sort.asc(u32));
    std.debug.print("List 2 after: {any}\n", .{list2[0..@min(5, list2_index)]});

    var distance: u32 = 0;
    for (0..list1_index) |index| {
        distance += @max(list2[index], list1[index]) - @min(list2[index], list1[index]);
    }
    std.debug.print("Distance: {d}\n", .{distance});

    std.debug.print("Part 2 of Day 1\n", .{});

    var previous_number: u32 = 0;
    var ocurrences: u32 = 0;
    var similarity: u32 = 0;

    for (0..list1_index) |index| {
        if (list1[index] == previous_number) {
            similarity += ocurrences * list1[index];
        } else {
            previous_number = list1[index];
            ocurrences = 0;
            for (0..list2_index) |index2| {
                if (list1[index] < list2[index2]) {
                    break;
                }
                if (list1[index] == list2[index2]) {
                    ocurrences += 1;
                }
            }
            similarity += ocurrences * list1[index];
        }
    }
    std.debug.print("Similarity: {d}\n", .{similarity});
}
