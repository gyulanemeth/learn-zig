function createImageManipulationFunctions(context, selectionContext, height, width) {
    const selection = new Uint8ClampedArray(canvas.height * canvas.width)
    selection.fill(0)

    function invert() {
        const start = performance.now()

        const imgData = context.getImageData(0, 0, canvas.width, canvas.height);

        const rowLength = imgData.width * 4
        for (let idx = 0; idx < imgData.data.length; idx += 4) {
            const r = 255 - imgData.data[idx]
            const g = 255 - imgData.data[idx + 1]
            const b = 255 - imgData.data[idx + 2]

            imgData.data[idx] = r
            imgData.data[idx + 1] = g
            imgData.data[idx + 2] = b
        }

        context.putImageData(imgData, 0, 0)
        const execSpan = document.getElementById('exec-time')
        execSpan.innerHTML = performance.now() - start
    }

    function getPixelIndices(width, x, y) {
        const rIdx = y * (width * 4) + x * 4
        const gIdx = rIdx + 1
        const bIdx = rIdx + 2
        const aIdx = rIdx + 3

        return [ rIdx, gIdx, bIdx, aIdx ]
    }

    function getPixel(imgData, x, y) {
        const [ rIdx, gIdx, bIdx, aIdx ] = getPixelIndices(imgData.width, x, y)

        return {
            r: imgData.data[rIdx],
            g: imgData.data[gIdx],
            b: imgData.data[bIdx],
            a: imgData.data[aIdx]
        }
    }

    function setPixel(imgData, x, y, { r, g, b, a }) {
        const [ rIdx, gIdx, bIdx, aIdx ] = getPixelIndices(imgData.width, x, y)

        imgData.data[rIdx] = r
        imgData.data[gIdx] = g
        imgData.data[bIdx] = b
        imgData.data[aIdx] = a
    }

    

    function toGrayscale() {
        const start = performance.now()
        const imgData = context.getImageData(0, 0, canvas.width, canvas.height);

        for (let rIdx = 0; rIdx < imgData.height; rIdx += 1) {
            for (let cIdx = 0; cIdx < imgData.width; cIdx += 1) {
                const pixel = getPixel(imgData, cIdx, rIdx)
                const avg = Math.floor((pixel.r + pixel.g + pixel.b) / 3)
                pixel.r = avg
                pixel.g = avg
                pixel.b = avg

                setPixel(imgData, cIdx, rIdx, pixel)
            }
        }
        context.putImageData(imgData, 0, 0)
        const execSpan = document.getElementById('exec-time')
        execSpan.innerHTML = performance.now() - start
    }

    function convolution(kernel) {
        const start = performance.now()
        const imgData = context.getImageData(0, 0, canvas.width, canvas.height);

        const newImageData = context.createImageData(imgData);

        const maxX = imgData.width - 1
        const maxY = imgData.height - 1

        function avgPixels(imgData, pixelCoords, kernel) {
            const newPixel = { r: 0, g: 0, b: 0, a: 255 } // 255 alpha is temporal...
            for (let idx = 0; idx < pixelCoords.length; idx += 1) {
                const actCoord = pixelCoords[idx]
                const actKernel = kernel[idx]
                const actPixel = getPixel(imgData, actCoord.x, actCoord.y)
                newPixel.r += actKernel * actPixel.r
                newPixel.g += actKernel * actPixel.g
                newPixel.b += actKernel * actPixel.b
            }

            return newPixel
        }
        // corners
        /*
            kernel matrix help:

            [
                kernel[0], kernel[1], kernel[2],
                kernel[3], kernel[4], kernel[5],
                kernel[6], kernel[7], kernel[8]
            ]
        */
        // top-left
        setPixel(newImageData, 0, 0, avgPixels(imgData, [
            { x: 0, y: 0 },
            { x: 0, y: 1 },
            { x: 1, y: 0 },
            { x: 1, y: 1 }
        ], [kernel[4], kernel[7], kernel[5], kernel[8]]))
        // top-right
        setPixel(newImageData, maxX, 0, avgPixels(imgData, [
            { x: maxX, y: 0 },
            { x: maxX, y: 1 },
            { x: maxX - 1, y: 0 },
            { x: maxX - 1, y: 1 }
        ], [kernel[4], kernel[7], kernel[3], kernel[6]]))
        // bottom-left
        setPixel(newImageData, 0, maxY, avgPixels(imgData, [
            { x: 0, y: maxY },
            { x: 0, y: maxY - 1 },
            { x: 1, y: maxY },
            { x: 1, y: maxY - 1 }
        ], kernel[4], kernel[1], kernel[5], kernel[2]))
        // bottom-right
        setPixel(newImageData, maxX, maxY, avgPixels(imgData, [
            { x: maxX, y: maxY },
            { x: maxX, y: maxY - 1 },
            { x: maxX - 1, y: maxY },
            { x: maxX - 1, y: maxY - 1 }
        ], kernel[4], kernel[1], kernel[3], kernel[0]))

        // edges
        // top & bottom
        for (let cIdx = 1; cIdx < maxX; cIdx += 1) {
            const topIndices = [
                { x: cIdx - 1, y: 0 },
                { x: cIdx, y: 0 },
                { x: cIdx + 1, y: 0 },
                { x: cIdx - 1, y: 1 },
                { x: cIdx, y: 1 },
                { x: cIdx + 1, y: 1 }
            ]
            setPixel(newImageData, cIdx, 0, avgPixels(imgData, topIndices, [
                kernel[3], kernel[4], kernel[5], kernel[6], kernel[7], kernel[8]
            ]))

            const bottomIndices = [
                { x: cIdx - 1, y: maxY - 1 },
                { x: cIdx, y: maxY - 1 },
                { x: cIdx + 1, y: maxY - 1 },
                { x: cIdx - 1, y: maxY },
                { x: cIdx, y: maxY },
                { x: cIdx + 1, y: maxY }
            ]
            setPixel(newImageData, cIdx, maxY, avgPixels(imgData, bottomIndices, [
                kernel[0], kernel[1], kernel[2], kernel[3], kernel[4], kernel[5]
            ]))
        }
        // left & right
        for (let rIdx = 0; rIdx < maxY; rIdx += 1) {
            const leftIndices = [
                { x: 0, y: rIdx - 1 },
                { x: 0, y: rIdx },
                { x: 0, y: rIdx + 1 },
                { x: 1, y: rIdx - 1 },
                { x: 1, y: rIdx },
                { x: 1, y: rIdx + 1 }
            ]
            setPixel(newImageData, 0, rIdx, avgPixels(imgData, leftIndices, [
                kernel[1], kernel[2], kernel[4], kernel[5], kernel[7], kernel[8]
            ]))

            const rightIndices = [
                { x: maxX - 1, y: rIdx - 1 },
                { x: maxX - 1, y: rIdx },
                { x: maxX - 1, y: rIdx + 1 },
                { x: maxX, y: rIdx - 1 },
                { x: maxX, y: rIdx },
                { x: maxX, y: rIdx + 1 }
            ]
            setPixel(newImageData, maxX, rIdx, avgPixels(imgData, rightIndices, [
                kernel[0], kernel[1], kernel[3], kernel[4], kernel[6], kernel[7]
            ]))
        }


        // middle part
        for (let rIdx = 1; rIdx < maxY; rIdx += 1) {
            for (let cIdx = 1; cIdx < maxX; cIdx += 1) {
                const indices = [
                    { y: rIdx - 1, x: cIdx - 1},
                    { y: rIdx - 1, x: cIdx},
                    { y: rIdx - 1, x: cIdx + 1},
                    { y: rIdx, x: cIdx - 1},
                    { y: rIdx, x: cIdx},
                    { y: rIdx, x: cIdx + 1},
                    { y: rIdx + 1, x: cIdx - 1},
                    { y: rIdx + 1, x: cIdx},
                    { y: rIdx + 1, x: cIdx + 1}
                ]
                setPixel(newImageData, cIdx, rIdx, avgPixels(imgData, indices, kernel))
            }
        }

        context.putImageData(newImageData, 0, 0)
        const execSpan = document.getElementById('exec-time')
        execSpan.innerHTML = performance.now() - start
    }

    function blur() {
        const kernel = [
            0.1, 0.1, 0.1,
            0.1, 0.2, 0.1,
            0.1, 0.1, 0.1
        ]

        convolution(kernel)
    }

    function edgeDetection() {
        const kernel = [
            -1, -1, -1,
            -1, 8, -1,
            -1, -1, -1
        ]

        convolution(kernel)
    }

    function sharpen() {
        const kernel = [
            0, -1, 0,
            -1, 5, -1,
            0, -1, 0
        ]

        convolution(kernel)
    }

    function emboss() {
        const kernel = [
            -2, -1, 0,
            -1, 1, 1,
            0, 1, 2
        ]

        convolution(kernel)
    }

    function motionBlur() {
        const kernel = [
            0.33, 0, 0,
            0.34, 0, 0,
            0.33, 0, 0
        ]

        convolution(kernel)
    }

    function edgeDetectionPerwittHorizontal() {
        const kernel = [
            -1, 0, 1,
            -1, 0, 1,
            -1, 0, 1
        ]

        convolution(kernel)
    }

    function edgeDetectionPerwittVertical() {
        const kernel = [
            -1, -1, -1,
            0, 0, 0,
            1, 1, 1
        ]

        convolution(kernel)
    }

    function edgeDetectionSobelHorizontal() {
        const kernel = [
            -1, 0, 1,
            -2, 0, 2,
            -1, 0, 1
        ]

        convolution(kernel)
    }

    function edgeDetectionSobelVertical() {
        const kernel = [
            -1, -2, -1,
            0, 0, 0,
            1, 2, 1
        ]

        convolution(kernel)
    }

    const radInDeg = 180 / Math.PI
    function rgbToHsl({ r, g, b, a }) {
        const max = Math.max(r, g, b)
        const min = Math.min(r, g, b)
        const diff = (max - min) / 255

        const l = (max + min) / 510
        const s = l == 0 ? 0 : diff / (1 - Math.abs(2 * l - 1))

        let h = 0
        if (s > Number.EPSILON) {
            h = radInDeg * Math.acos((r - 0.5 * g - 0.5 * b) / Math.sqrt(r * r + g * g + b * b - r * g - r * b - g * b))

            if (b > g) {
                h = 360 - h
            }
        }

        return { h, s, l, a }
    }

    function hslToRgb({ h, s, l, a }) {
        const diff = s * (1 - Math.abs(2 * l - 1))
        const min = 255 * (l - 0.5 * diff)

        const x = diff * (1 - Math.abs((h / 60) % 2 - 1))

        let r, g, b
        const val1 = 255 * diff + min
        const val2 = 255 * x + min
        if (h < 60) {
            r = val1
            g = val2
            b = min
        } else if (h < 120) {
            r = val2
            g = val1
            b = min
        } else if (h < 180) {
            r = min
            g = val1
            b = val2
        } else if (h < 240) {
            r = min
            g = val2
            b = val1
        } else if (h < 300) {
            r = val2
            g = min
            b = val1
        } else {
            r = val1
            g = min
            b = val2
        }

        return {r, g, b, a}
    }

    function rotateHueBy10Deg() {
        const start = performance.now()

        const imgData = context.getImageData(0, 0, canvas.width, canvas.height);

        for (let idx = 0; idx < imgData.data.length; idx += 4) {
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

    function setSelectionValueBasedOnHue({x, y}, value) {
        const hueDiff = 22 // pass it as a param later

        const start = performance.now()

        const imgData = context.getImageData(0, 0, canvas.width, canvas.height);
        const rgbPx = getPixel(imgData, x, y)
        const hslPx = rgbToHsl(rgbPx)

        const hueMin = hslPx.h - hueDiff
        const hueMax = hslPx.h + hueDiff

        const visited = new Uint8ClampedArray(canvas.height * canvas.width)
        visited.fill(0)
        
        const coordsToVisit = []
        coordsToVisit.push({x, y})

        while(coordsToVisit.length > 0) {
            const actCoord = coordsToVisit.shift()
            if (actCoord.x < 0 || actCoord.y < 0) {
                continue
            }

            if (actCoord.x >= canvas.width || actCoord.y >= canvas.height) {
                continue
            }

            if (visited[actCoord.y * canvas.width + actCoord.x] === 1) {
                continue
            }

            visited[actCoord.y * canvas.width + actCoord.x] = value

            const actRgb = getPixel(imgData, actCoord.x, actCoord.y)
            const actHsl = rgbToHsl(actRgb)

            if (actHsl.h < hueMin) {
                continue
            }

            if (actHsl.h > hueMax) {
                continue
            }

            selection[actCoord.y * canvas.width + actCoord.x] = 1

            coordsToVisit.push({ y: actCoord.y - 1, x: actCoord.x - 1 })
            coordsToVisit.push({ y: actCoord.y - 1, x: actCoord.x })
            coordsToVisit.push({ y: actCoord.y - 1, x: actCoord.x + 1 })

            coordsToVisit.push({ y: actCoord.y, x: actCoord.x - 1 })
            coordsToVisit.push({ y: actCoord.y, x: actCoord.x + 1 })

            coordsToVisit.push({ y: actCoord.y + 1, x: actCoord.x - 1 })
            coordsToVisit.push({ y: actCoord.y + 1, x: actCoord.x })
            coordsToVisit.push({ y: actCoord.y + 1, x: actCoord.x + 1 })
        }
        drawSelectedPixels()
    }

    function addToSelectionBasedOnHue({x, y}) {
        setSelectionValueBasedOnHue({x, y}, 1)
    }

    function removeFromSelectionBasedOnHue({x, y}) {
        setSelectionValueBasedOnHue({x, y}, 1)
    }

    function saturateSelection() {
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
            hsla.s = 1

            const newRgba = hslToRgb(hsla)
            imgData.data[idx] = newRgba.r
            imgData.data[idx + 1] = newRgba.g
            imgData.data[idx + 2] = newRgba.b
            imgData.data[idx + 3] = newRgba.a
        }
        context.putImageData(imgData, 0, 0)
        drawSelectedPixels()
    }

    function desaturateSelection() {
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
            hsla.s = 0

            const newRgba = hslToRgb(hsla)
            imgData.data[idx] = newRgba.r
            imgData.data[idx + 1] = newRgba.g
            imgData.data[idx + 2] = newRgba.b
            imgData.data[idx + 3] = newRgba.a
        }
        context.putImageData(imgData, 0, 0)
        drawSelectedPixels()
    }

    function selectAll() {
        selection.fill(1)
        drawSelectedPixels()
    }

    function deselectAll() {
        selection.fill(0)
        drawSelectedPixels()
    }

    function invertSelection() {
        for (let idx = 0; idx < selection.length; idx += 1) {
            selection[idx] = Math.abs(selection[idx] - 1)
        }
        drawSelectedPixels()
    }

    function drawSelectedPixels() {
        const imgData = context.getImageData(0, 0, canvas.width, canvas.height);
        for (let idx = 0; idx < selection.length; idx += 1) {
            if (selection[idx] === 0) {
                const imgIdx = idx * 4
                imgData.data[imgIdx] = 0
                imgData.data[imgIdx + 1] = 0
                imgData.data[imgIdx + 2] = 0
                imgData.data[imgIdx + 3] = 0
            }
        }
        selectionContext.putImageData(imgData, 0, 0)
    }

    return {
        invert,
        toGrayscale,
        blur,
        sharpen,
        edgeDetection,
        emboss,
        motionBlur,
        edgeDetectionPerwittHorizontal,
        edgeDetectionPerwittVertical,
        edgeDetectionSobelHorizontal,
        edgeDetectionSobelVertical,

        rotateHueBy10Deg,

        selectAll,
        deselectAll,
        addToSelectionBasedOnHue,
        removeFromSelectionBasedOnHue,
        invertSelection,

        saturateSelection,
        desaturateSelection
    }
}