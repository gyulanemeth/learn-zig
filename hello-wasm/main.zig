extern fn inc(a: i32) i32;

export fn addInc(a: i32, b: i32) i32 {
    return inc(a) + b;
}
