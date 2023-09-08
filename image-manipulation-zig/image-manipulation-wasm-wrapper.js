async function createWasmWrapper(context, height, width) {
    const importObject = {
        env: {
            debug: () => {}
        }
    }

    let start = performance.now()
    const results = await WebAssembly.instantiateStreaming(fetch("./imgage-manipulation.wasm"), importObject)
    const wasmIface = results.instance.exports
    let end = performance.now()
    console.log('wasm load', end - start)

    start = end
    const imgData = context.getImageData(0, 0, width, height);
    const memoryAddr = wasmIface.init(imgData.height, imgData.width)
    end = performance.now()
    console.log('wasm - allocate memory', end - start)

    start = end
    new Uint8Array(wasmIface.memory.buffer).set(imgData.data, memoryAddr)
    end = performance.now()
    console.log('pixels -> wasm', end - start)


    function callWasmFunction(name) {
        const start = performance.now()
        const imgData = context.getImageData(0, 0, width, height);

        wasmIface[name]()
        const addr = wasmIface.currentImgAddress()
        const imgArray = new Uint8ClampedArray(wasmIface.memory.buffer, addr, imgData.data.length)

        const newImgData = new ImageData(imgArray, imgData.width, imgData.height)
        context.putImageData(newImgData, 0, 0)
        const execSpan = document.getElementById('exec-time')
        execSpan.innerHTML = performance.now() - start
    }

    return {
        invert: () => callWasmFunction('invert'),
        toGrayscale: () => callWasmFunction('to_grayscale'),
        blur: () => callWasmFunction('blur'),
        sharpen: () => callWasmFunction('sharpen'),
        edgeDetection: () => callWasmFunction('edge_detection')
    }
}