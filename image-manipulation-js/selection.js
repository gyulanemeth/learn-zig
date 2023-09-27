export default (imgData) => {
    const selection = new Uint8ClampedArray(imgData.height * imgData.width)
    // This will be useful, when I introduce fuzzy selecitons:
    // const selection = new Float32Array(imgData.height * imgData.width)
    selection.fill(0)

    function selectAll() {
        selection.fill(1)
        drawSelectedPixels()
    }

    function deselectAll() {
        selection.fill(0)
        drawSelectedPixels()
    }

    function invert() {
        for (let idx = 0; idx < selection.length; idx += 1) {
            selection[idx] = Math.abs(selection[idx] - 1)
        }
        drawSelectedPixels()
    }

    function setSelectionValueBasedOnHslRange({x, y}, value) {
        const hueDiff = 20
        const lightnessDiff = 0.1
        const saturationDiff = 0.1

        const start = performance.now()

        const imgData = context.getImageData(0, 0, canvas.width, canvas.height);
        const rgbPx = getPixel(imgData, x, y)
        const hslPx = rgbToHsl(rgbPx)

        const hueMin = hslPx.h - hueDiff
        const hueMax = hslPx.h + hueDiff
        const lightnessMin = hslPx.l - lightnessDiff
        const lightnessMax = hslPx.l + lightnessDiff
        const saturationMin = hslPx.s - saturationDiff
        const saturationMax = hslPx.s + saturationDiff

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

            if (actHsl.l < lightnessMin) {
                continue
            }

            if (actHsl.l > lightnessMax) {
                continue
            }

            if (actHsl.s < saturationMin) {
                continue
            }

            if (actHsl.s > saturationMax) {
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

    function setSelectionBasedOnHeighbouringHslRange({x, y}, value) {
        const hueDiff = 30
        const lightnessDiff = 0.2
        const saturationDiff = 0.25

        const start = performance.now()

        const imgData = context.getImageData(0, 0, canvas.width, canvas.height);
        const rgbPx = getPixel(imgData, x, y)
        const hslPx = rgbToHsl(rgbPx)

        const visited = new Uint8ClampedArray(canvas.height * canvas.width)
        visited.fill(0)
        
        const coordsToVisit = []
        coordsToVisit.push({ coord: {x, y}, hsl: hslPx })

        while(coordsToVisit.length > 0) {
            const act = coordsToVisit.shift()
            const actCoord = act.coord
            const hslPx = act.hsl

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

            let hueMin = hslPx.h - hueDiff
            let hueMax = hslPx.h + hueDiff
            let lightnessMin = hslPx.l - lightnessDiff
            let lightnessMax = hslPx.l + lightnessDiff
            let saturationMin = hslPx.s - saturationDiff
            let saturationMax = hslPx.s + saturationDiff

            const actRgb = getPixel(imgData, actCoord.x, actCoord.y)
            const actHsl = rgbToHsl(actRgb)

            if (actHsl.h < hueMin) {
                continue
            }

            if (actHsl.h > hueMax) {
                continue
            }

            if (actHsl.l < lightnessMin) {
                continue
            }

            if (actHsl.l > lightnessMax) {
                continue
            }

            if (actHsl.s < saturationMin) {
                continue
            }

            if (actHsl.s > saturationMax) {
                continue
            }

            selection[actCoord.y * canvas.width + actCoord.x] = 1

            coordsToVisit.push({ coord: { y: actCoord.y - 1, x: actCoord.x - 1 }, hsl: actHsl })
            coordsToVisit.push({ coord: { y: actCoord.y - 1, x: actCoord.x }, hsl: actHsl })
            coordsToVisit.push({ coord: { y: actCoord.y - 1, x: actCoord.x + 1 }, hsl: actHsl })

            coordsToVisit.push({ coord: { y: actCoord.y, x: actCoord.x - 1 }, hsl: actHsl })
            coordsToVisit.push({ coord: { y: actCoord.y, x: actCoord.x + 1 }, hsl: actHsl })

            coordsToVisit.push({ coord: { y: actCoord.y + 1, x: actCoord.x - 1 }, hsl: actHsl })
            coordsToVisit.push({ coord: { y: actCoord.y + 1, x: actCoord.x }, hsl: actHsl })
            coordsToVisit.push({ coord: { y: actCoord.y + 1, x: actCoord.x + 1 }, hsl: actHsl })
        }
        drawSelectedPixels()
    }

    function addR({x, y}, r) {
        // TODO: implement distance-based stuff
        const coordsToVisit = []
        coordsToVisit.push({x, y})
        coordsToVisit.push({ y: y - 1, x: x - 1 })
        coordsToVisit.push({ y: y - 1, x: x })
        coordsToVisit.push({ y: y - 1, x: x + 1 })

        coordsToVisit.push({ y: y, x: x - 1 })
        coordsToVisit.push({ y: y, x: x + 1 })

        coordsToVisit.push({ y: y + 1, x: x - 1 })
        coordsToVisit.push({ y: y + 1, x: x })
        coordsToVisit.push({ y: y + 1, x: x + 1 })

        while(coordsToVisit.length > 0) {
            const actCoord = coordsToVisit.shift()
            selection[actCoord.y * canvas.width + actCoord.x] = 1
        }
        drawSelectedPixels()
    }

    function addBasedOnHslRange({x, y}) {
        setSelectionValueBasedOnHslRange({x, y}, 1)
    }

    function removeBasedOnHslRange({x, y}) {
        setSelectionValueBasedOnHslRange({x, y}, 0)
    }

    function addBasedOnNeighboringHslRange({x, y}) {
        setSelectionBasedOnHeighbouringHslRange({x, y}, 1)
    }

    function removeBasedOnNeighbouringHslRange({x, y}) {
        setSelectionBasedOnHeighbouringHslRange({x, y}, 0)
    }

    return {
        selectAll,
        deselectAll,
        invert,

        addR,
        addBasedOnHslRange,
        removeBasedOnHslRange,
        addBasedOnNeighboringHslRange,
        removeBasedOnNeighbouringHslRange
    }
}