(module
    (global $g (import "test" "global") (mut i32))
    (func (export "getGlobal") (result i32)
        global.get $g
    )
    (func (export "incGlobal") 
        global.get $g
        i32.const 1
        i32.add
        global.set $g
    )
)
