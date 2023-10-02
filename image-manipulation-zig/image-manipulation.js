function createImageManipulationFunctions(context, selectionContext, height, width) {
    const selection = new Uint8ClampedArray(canvas.height * canvas.width)
    selection.fill(0)

    

    

    

    

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