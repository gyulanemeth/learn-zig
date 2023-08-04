const expect = @import("std").testing.expect;

fn rangeHasNumber(begin: usize, end: usize, number: usize) bool {
    var i = begin;
    return while (i < end) : (i += 1) {
        if (i == number) {
            break true;
        }
    } else false;
}

test "while loop expression" {
    try expect(rangeHasNumber(2, 10, 3));
    try expect(!rangeHasNumber(2, 10, 11));
}
