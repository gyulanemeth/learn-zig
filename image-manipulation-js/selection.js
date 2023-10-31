import { getPixel } from './pixels.js'
import { rgbToHsl } from './convert.js'

export default (imgData, drawSelectedPixels = () => {}) => {
    const selection = new Uint8ClampedArray(imgData.height * imgData.width)
    // This will be useful, when I introduce fuzzy selecitons:
    // const selection = new Float32Array(imgData.height * imgData.width)
    selection.fill(0)

    drawSelectedPixels(selection)

    function selectAll() {
        selection.fill(1)
        drawSelectedPixels(selection)
    }

    function deselectAll() {
        selection.fill(0)
        drawSelectedPixels(selection)
    }

    function invert() {
        for (let idx = 0; idx < selection.length; idx += 1) {
            selection[idx] = 1 - selection[idx]
        }
        drawSelectedPixels(selection)
    }

    function rectangularSelection(from, to) {
      const fromX = Math.min(from.x, to.x)
      const toX = Math.max(from.x, to.x)

      const fromY = Math.min(from.y, to.y)
      const toY = Math.max(from.y, to.y)

      for (let yIdx = fromY; yIdx < toY; yIdx += 1) {
        for (let xIdx = fromX; xIdx < toX; xIdx += 1) {
          selection[yIdx * imgData.width + xIdx] = 1
        }
      }

      drawSelectedPixels(selection)
    }

    function setSelectionValueBasedOnHslRange({x, y}, value) {
        const hueDiff = 20
        const lightnessDiff = 0.1
        const saturationDiff = 0.1

        const rgbPx = getPixel(imgData, x, y)
        const hslPx = rgbToHsl(rgbPx)

        const hueMin = hslPx.h - hueDiff
        const hueMax = hslPx.h + hueDiff
        const lightnessMin = hslPx.l - lightnessDiff
        const lightnessMax = hslPx.l + lightnessDiff
        const saturationMin = hslPx.s - saturationDiff
        const saturationMax = hslPx.s + saturationDiff

        const visited = new Uint8ClampedArray(imgData.height * imgData.width)
        visited.fill(0)
        
        const coordsToVisit = []
        coordsToVisit.push({x, y})

        while(coordsToVisit.length > 0) {
            const actCoord = coordsToVisit.shift()
            if (actCoord.x < 0 || actCoord.y < 0) {
                continue
            }

            if (actCoord.x >= imgData.width || actCoord.y >= imgData.height) {
                continue
            }

            if (visited[actCoord.y * imgData.width + actCoord.x] === 1) {
                continue
            }

            visited[actCoord.y * imgData.width + actCoord.x] = value

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

            selection[actCoord.y * imgData.width + actCoord.x] = 1

            coordsToVisit.push({ y: actCoord.y - 1, x: actCoord.x - 1 })
            coordsToVisit.push({ y: actCoord.y - 1, x: actCoord.x })
            coordsToVisit.push({ y: actCoord.y - 1, x: actCoord.x + 1 })

            coordsToVisit.push({ y: actCoord.y, x: actCoord.x - 1 })
            coordsToVisit.push({ y: actCoord.y, x: actCoord.x + 1 })

            coordsToVisit.push({ y: actCoord.y + 1, x: actCoord.x - 1 })
            coordsToVisit.push({ y: actCoord.y + 1, x: actCoord.x })
            coordsToVisit.push({ y: actCoord.y + 1, x: actCoord.x + 1 })
        }
        drawSelectedPixels(selection)
    }

    function setSelectionBasedOnHeighbouringHslRange({x, y}, value) {
        const hueDiff = 5
        const lightnessDiff = 0.2
        const saturationDiff = 0.2

        const start = performance.now()

        const rgbPx = getPixel(imgData, x, y)
        const hslPx = rgbToHsl(rgbPx)

        const visited = new Uint8ClampedArray(imgData.height * imgData.width)
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

            if (actCoord.x >= imgData.width || actCoord.y >= imgData.height) {
                continue
            }

            if (visited[actCoord.y * imgData.width + actCoord.x] === 1) {
                continue
            }

            visited[actCoord.y * imgData.width + actCoord.x] = value

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

            selection[actCoord.y * imgData.width + actCoord.x] = 1

            coordsToVisit.push({ coord: { y: actCoord.y - 1, x: actCoord.x - 1 }, hsl: actHsl })
            coordsToVisit.push({ coord: { y: actCoord.y - 1, x: actCoord.x }, hsl: actHsl })
            coordsToVisit.push({ coord: { y: actCoord.y - 1, x: actCoord.x + 1 }, hsl: actHsl })

            coordsToVisit.push({ coord: { y: actCoord.y, x: actCoord.x - 1 }, hsl: actHsl })
            coordsToVisit.push({ coord: { y: actCoord.y, x: actCoord.x + 1 }, hsl: actHsl })

            coordsToVisit.push({ coord: { y: actCoord.y + 1, x: actCoord.x - 1 }, hsl: actHsl })
            coordsToVisit.push({ coord: { y: actCoord.y + 1, x: actCoord.x }, hsl: actHsl })
            coordsToVisit.push({ coord: { y: actCoord.y + 1, x: actCoord.x + 1 }, hsl: actHsl })
        }
        drawSelectedPixels(selection)
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
            selection[actCoord.y * imgData.width + actCoord.x] = 1
        }
        drawSelectedPixels(selection)
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

    function sumCoords(coords) {
      let sum = 0

      for (let idx = 0; idx < coords.length; idx += 1) {
        sum += selection[coords[idx].y * imgData.width + coords[idx].x]
      }

      return sum
    }

    function dilate() {
      const newSelection = new Uint8ClampedArray(imgData.height * imgData.width)
      const maxY = imgData.height - 1
      const maxX = imgData.width - 1

      // top-left corner: (0, 0)
      const tlSum = sumCoords([
        { x: 0, y: 1 },
        { x: 1, y: 0 },
        { x: 1, y: 1 }
      ])

      if (tlSum > 1) {
        newSelection[0] = 1
      } else {
        newSelection[0] = 0
      }

      // top-right corner: (maxX, 0)
      const trSum = sumCoords([
        { x: maxX, y: 1 },
        { x: maxX - 1, y: 0 },
        { x: maxX - 1, y: 1 }
      ])

      if (trSum > 1) {
        newSelection[maxX] = 1
      } else {
        newSelection[maxX] = 0
      }

      // bottom-left corner: (0, maxY)
      const blSum = sumCoords([
        { x: 0, y: maxY - 1 },
        { x: 1, y: maxY },
        { x: 1, y: maxY - 1 }
      ])

      if (blSum > 1) {
        newSelection[maxY] = 1
      } else {
        newSelection[maxY] = 0
      }

      // bottom-right corner: (maxX, maxY)
      const brSum = sumCoords([
        { x: maxX, y: maxY - 1 },
        { x: maxX - 1, y: maxY },
        { x: maxX - 1, y: maxY - 1 }
      ])

      if (brSum > 1) {
        newSelection[maxY * imgData.width + maxX] = 1
      } else {
        newSelection[maxY * imgData.width + maxX] = 0
      }

      // top & bottom edges
      for (let cIdx = 1; cIdx < maxX; cIdx += 1) {
        const topSum = sumCoords([
          { x: cIdx - 1, y: 0 },
          { x: cIdx + 1, y: 0 },
          { x: cIdx - 1, y: 1 },
          { x: cIdx, y: 1 },
          { x: cIdx + 1, y: 1 }
        ])

        if (topSum > 3) {
          newSelection[cIdx] = 1
        } else {
          newSelection[cIdx] = 0
        }

        const bottomSum = sumCoords([
          { x: cIdx - 1, y: maxY - 1 },
          { x: cIdx, y: maxY - 1 },
          { x: cIdx + 1, y: maxY - 1 },
          { x: cIdx - 1, y: maxY },
          { x: cIdx + 1, y: maxY }
        ])

        if (bottomSum > 3) {
          newSelection[maxY * imgData.width + cIdx] = 1
        } else {
          newSelection[maxY * imgData.width + cIdx] = 0
        }
      }

      // left & right edges
      for (let rIdx = 0; rIdx < maxY; rIdx += 1) {
        const leftSum = sumCoords([
          { x: 0, y: rIdx - 1 },
          { x: 0, y: rIdx },
          { x: 0, y: rIdx + 1 },
          { x: 1, y: rIdx - 1 },
          { x: 1, y: rIdx },
          { x: 1, y: rIdx + 1 }
        ])

        if (leftSum > 3) {
          newSelection[rIdx * imgData.width] = 1
        } else {
          newSelection[rIdx * imgData.width] = 0
        }

        const rightSum = sumCoords([
          { x: maxX - 1, y: rIdx - 1 },
          { x: maxX - 1, y: rIdx },
          { x: maxX - 1, y: rIdx + 1 },
          { x: maxX, y: rIdx - 1 },
          { x: maxX, y: rIdx },
          { x: maxX, y: rIdx + 1 }
        ])

        if (rightSum > 3) {
          newSelection[rIdx * imgData.width + maxX] = 1
        } else {
          newSelection[rIdx * imgData.width + maxX] = 0
        }
      }

      for (let rIdx = 1; rIdx < maxY; rIdx += 1) {
        for (let cIdx = 1; cIdx < maxX; cIdx += 1) {
          const sum = sumCoords([
            { y: rIdx - 1, x: cIdx - 1},
            { y: rIdx - 1, x: cIdx},
            { y: rIdx - 1, x: cIdx + 1},
            { y: rIdx, x: cIdx - 1},
            { y: rIdx, x: cIdx + 1},
            { y: rIdx + 1, x: cIdx - 1},
            { y: rIdx + 1, x: cIdx},
            { y: rIdx + 1, x: cIdx + 1}
          ])

          if (sum > 3) {
            newSelection[rIdx * imgData.width + cIdx] = 1
          } else {
            newSelection[rIdx * imgData.width + cIdx] = 0
          }
        }
      }
      selection.set(newSelection)
      drawSelectedPixels(selection)
    }

    return {
        selection,

        selectAll,
        deselectAll,
        invert,

        rectangularSelection,

        addR,
        addBasedOnHslRange,
        removeBasedOnHslRange,
        addBasedOnNeighboringHslRange,
        removeBasedOnNeighbouringHslRange,

        dilate
    }
}
