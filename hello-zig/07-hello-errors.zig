const std = @import("std");
const expect = std.testing.expect;
const print = std.debug.print;

const FileOpenError = error{ AccessDenied, OutOfMemory, FileNotFound };
const AllocationError = error{OutOfMemory};

test "coerce error from a subset to a superset" {
    const err: FileOpenError = AllocationError.OutOfMemory;
    try expect(err == FileOpenError.OutOfMemory);
}

test "error union" {
    const maybe_error: AllocationError!u16 = 10;
    const no_error = maybe_error catch 0;

    try expect(@TypeOf(no_error) == u16);
    try expect(no_error == 10);
}

fn failingFunction() error{Whooops}!void {
    return error.Whooops;
}

test "returning an error" {
    failingFunction() catch |err| {
        try expect(err == error.Whooops);
        return;
    };
}

fn failFn() error{Whooops}!i32 {
    // failingFunction() catch |err| return err;
    try failingFunction();
    return 12;
}

test "try" {
    var v = failFn() catch |err| {
        print("err: {}\n", .{err});
        try expect(err == error.Whooops);
        return;
    };
    print("return value: {}\n", .{v});
    try expect(v == 12);
}

var problems: u16 = 99;

fn failFnCounter() error{Whooops}!void {
    errdefer problems += 1;
    try failingFunction();
}

test "errdefer" {
    failFnCounter() catch |err| {
        try expect(err == error.Whooops);
        try expect(problems == 100);
        return;
    };

    print("problems: {}\n", .{problems});
    try expect(problems == 99);
}

fn createFile() !void {
    return error.AccessDenied;
}

test "inferred error set" {
    const x: error{AccessDenied}!void = createFile();

    _ = x catch {};
}
