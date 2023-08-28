extern fn inc(a: i32) i32;

export fn yo(a: i32) i32 {
    return a + 2;
}

export fn addInc(a: i32, b: i32) i32 {
    return inc(a) + b;
}
