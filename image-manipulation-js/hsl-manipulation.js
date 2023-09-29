export default () => {
    function rotateHueBy10Deg() {
        const start = performance.now()

        const imgData = context.getImageData(0, 0, canvas.width, canvas.height);

        for (let idx = 0; idx < imgData.data.length; idx += 4) {
            if (selection[idx / 4] === 0) {
                continue
            }
            const r = imgData.data[idx]
            const g = imgData.data[idx + 1]
            const b = imgData.data[idx + 2]
            const a = imgData.data[idx + 3]

            const hsla = rgbToHsl({ r, g, b, a })
            hsla.h += 10
            hsla.h %= 360

            const newRgba = hslToRgb(hsla)
            imgData.data[idx] = newRgba.r
            imgData.data[idx + 1] = newRgba.g
            imgData.data[idx + 2] = newRgba.b
            imgData.data[idx + 3] = newRgba.a
        }

        context.putImageData(imgData, 0, 0)
        const execSpan = document.getElementById('exec-time')
        execSpan.innerHTML = performance.now() - start
    }

    

    function addSaturationToSelection(saturationDiff) {
        const imgData = context.getImageData(0, 0, canvas.width, canvas.height);
        for (let idx = 0; idx < imgData.data.length; idx += 4) {
            const coordIdx = idx / 4

            const r = imgData.data[idx]
            const g = imgData.data[idx + 1]
            const b = imgData.data[idx + 2]
            const a = imgData.data[idx + 3]

            if (selection[coordIdx] != 1) {
                continue
            }

            const hsla = rgbToHsl({ r, g, b, a })
            hsla.s += saturationDiff

            if (hsla.s > 1) {
                hsla.s = 1
            }

            if (hsla.s < 0) {
                hsla.s = 0
            }

            const newRgba = hslToRgb(hsla)
            imgData.data[idx] = newRgba.r
            imgData.data[idx + 1] = newRgba.g
            imgData.data[idx + 2] = newRgba.b
            imgData.data[idx + 3] = newRgba.a
        }
        context.putImageData(imgData, 0, 0)
        drawSelectedPixels()
    }

    function addLightnessToSelection(lightnessDiff) {
        const imgData = context.getImageData(0, 0, canvas.width, canvas.height);
        for (let idx = 0; idx < imgData.data.length; idx += 4) {
            const coordIdx = idx / 4

            const r = imgData.data[idx]
            const g = imgData.data[idx + 1]
            const b = imgData.data[idx + 2]
            const a = imgData.data[idx + 3]

            if (selection[coordIdx] != 1) {
                continue
            }

            const hsla = rgbToHsl({ r, g, b, a })
            hsla.l += lightnessDiff

            if (hsla.l > 1) {
                hsla.l = 1
            }

            if (hsla.l < 0) {
                hsla.l = 0
            }

            const newRgba = hslToRgb(hsla)
            imgData.data[idx] = newRgba.r
            imgData.data[idx + 1] = newRgba.g
            imgData.data[idx + 2] = newRgba.b
            imgData.data[idx + 3] = newRgba.a
        }
        context.putImageData(imgData, 0, 0)
        drawSelectedPixels()
    }

    function addHueToSelection(hueDiff) {
        const imgData = context.getImageData(0, 0, canvas.width, canvas.height);
        for (let idx = 0; idx < imgData.data.length; idx += 4) {
            const coordIdx = idx / 4

            const r = imgData.data[idx]
            const g = imgData.data[idx + 1]
            const b = imgData.data[idx + 2]
            const a = imgData.data[idx + 3]

            if (selection[coordIdx] != 1) {
                continue
            }

            const hsla = rgbToHsl({ r, g, b, a })
            hsla.h += hueDiff

            if (hsla.h < 0) {
                hsla.h += 360
            }

            if (hsla.h >= 360) {
                hsla.h -= 360
            }

            const newRgba = hslToRgb(hsla)
            imgData.data[idx] = newRgba.r
            imgData.data[idx + 1] = newRgba.g
            imgData.data[idx + 2] = newRgba.b
            imgData.data[idx + 3] = newRgba.a
        }
        context.putImageData(imgData, 0, 0)
        drawSelectedPixels()
    }
}