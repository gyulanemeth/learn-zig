(module
    (import "console" "log" (func $log (param i32 i32)))
    (import "js" "mem" (memory 1))
    (data (i32.const 0) "Hello")
    (func (export "writeHi")
        i32.const 0 ;; offset
        i32.const 5 ;; length
        call $log
    )
)