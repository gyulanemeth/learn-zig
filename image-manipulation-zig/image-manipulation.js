function createImageManipulationFunctions(context, selectionContext, height, width) {
    const selection = new Uint8ClampedArray(canvas.height * canvas.width)
    selection.fill(0)

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
        addToSelection,
        addToSelectionBasedOnHslRange,
        addToSelectionBasedOnNeighbouringHslRange,
        removeFromSelectionBasedOnHue,
        removeFromSelectionBasedOnNeighbouringHslRange,
        invertSelection,

        addSaturationToSelection,
        addLightnessToSelection,
        addHueToSelection
    }
}