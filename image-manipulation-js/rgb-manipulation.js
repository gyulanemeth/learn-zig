import { getPixel, setPixel } from './pixels.js'

export function invert(imgData, selection) {
    const newImgData = new ImageData(imgData.data, imgData.width, imgData.height)
    for (let idx = 0; idx < imgData.data.length; idx += 4) {
        if (selection[idx / 4] != 1) {
            continue
        }
        const r = 255 - imgData.data[idx]
        const g = 255 - imgData.data[idx + 1]
        const b = 255 - imgData.data[idx + 2]

        imgData.data[idx] = r
        imgData.data[idx + 1] = g
        imgData.data[idx + 2] = b
    }
    return newImgData
}

export function toGrayscale(imgData) {
    const newImgData = new ImageData(imgData.data, imgData.width, imgData.height)
    for (let rIdx = 0; rIdx < imgData.height; rIdx += 1) {
        for (let cIdx = 0; cIdx < imgData.width; cIdx += 1) {
            if (!selection[rIdx * imgData.width + cIdx]) {
                continue
            }

            const pixel = getPixel(imgData, cIdx, rIdx)
            const avg = Math.floor((pixel.r + pixel.g + pixel.b) / 3)
            pixel.r = avg
            pixel.g = avg
            pixel.b = avg

            setPixel(newImgData, cIdx, rIdx, pixel)
        }
    }
    return newImgData
}

export const convolutionKernels = {
    'blur': [
        0.1, 0.1, 0.1,
        0.1, 0.2, 0.1,
        0.1, 0.1, 0.1
    ],
    'motion-blur': [
        0.33, 0, 0,
        0.34, 0, 0,
        0.33, 0, 0
    ],
    'sharpen': [
        0, -1, 0,
        -1, 5, -1,
        0, -1, 0
    ],
    'emboss': [
        -2, -1, 0,
        -1, 1, 1,
        0, 1, 2
    ],
    'edge-detection': [
        -1, -1, -1,
        -1, 8, -1,
        -1, -1, -1
    ],
    'edge-detection-perwitt-horizontal': [
        -1, 0, 1,
        -1, 0, 1,
        -1, 0, 1
    ],
    'edge-detection-perwitt-vertical': [
        -1, -1, -1,
        0, 0, 0,
        1, 1, 1
    ],
    'edge-detection-sobel-horizontal': [
        -1, 0, 1,
        -2, 0, 2,
        -1, 0, 1
    ],
    'edge-detection-sobel-vertical': [
        -1, -2, -1,
        0, 0, 0,
        1, 2, 1
    ]

}

export function convolution(imgData, selection, kernel) {
    const newImgData = new ImageData(imgData.data, imgData.width, imgData.height)

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
    if (selection[0]) {
        setPixel(newImgData, 0, 0, avgPixels(imgData, [
            { x: 0, y: 0 },
            { x: 0, y: 1 },
            { x: 1, y: 0 },
            { x: 1, y: 1 }
        ], [kernel[4], kernel[7], kernel[5], kernel[8]]))
    }
    // top-right
    if (selection[maxX]) {
        setPixel(newImgData, maxX, 0, avgPixels(imgData, [
            { x: maxX, y: 0 },
            { x: maxX, y: 1 },
            { x: maxX - 1, y: 0 },
            { x: maxX - 1, y: 1 }
        ], [kernel[4], kernel[7], kernel[3], kernel[6]]))
    }
    // bottom-left
    if (selection[maxY * imgData.width]) {
        setPixel(newImgData, 0, maxY, avgPixels(imgData, [
            { x: 0, y: maxY },
            { x: 0, y: maxY - 1 },
            { x: 1, y: maxY },
            { x: 1, y: maxY - 1 }
        ], kernel[4], kernel[1], kernel[5], kernel[2]))
    }
    // bottom-right
    if (selection[maxY * imgData.width + maxX]) {
        setPixel(newImgData, maxX, maxY, avgPixels(imgData, [
            { x: maxX, y: maxY },
            { x: maxX, y: maxY - 1 },
            { x: maxX - 1, y: maxY },
            { x: maxX - 1, y: maxY - 1 }
        ], kernel[4], kernel[1], kernel[3], kernel[0]))
    }

    // edges
    // top & bottom
    for (let cIdx = 1; cIdx < maxX; cIdx += 1) {
        if (selection[cIdx]) {
            const topIndices = [
                { x: cIdx - 1, y: 0 },
                { x: cIdx, y: 0 },
                { x: cIdx + 1, y: 0 },
                { x: cIdx - 1, y: 1 },
                { x: cIdx, y: 1 },
                { x: cIdx + 1, y: 1 }
            ]
            setPixel(newImgData, cIdx, 0, avgPixels(imgData, topIndices, [
                kernel[3], kernel[4], kernel[5], kernel[6], kernel[7], kernel[8]
            ]))
        }

        if (selection[maxY * imgData.width + cIdx]) {
            const bottomIndices = [
                { x: cIdx - 1, y: maxY - 1 },
                { x: cIdx, y: maxY - 1 },
                { x: cIdx + 1, y: maxY - 1 },
                { x: cIdx - 1, y: maxY },
                { x: cIdx, y: maxY },
                { x: cIdx + 1, y: maxY }
            ]
            setPixel(newImgData, cIdx, maxY, avgPixels(imgData, bottomIndices, [
                kernel[0], kernel[1], kernel[2], kernel[3], kernel[4], kernel[5]
            ]))
        }
    }
    // left & right
    for (let rIdx = 0; rIdx < maxY; rIdx += 1) {
        if (selection[rIdx * imgData.width]) {
            const leftIndices = [
                { x: 0, y: rIdx - 1 },
                { x: 0, y: rIdx },
                { x: 0, y: rIdx + 1 },
                { x: 1, y: rIdx - 1 },
                { x: 1, y: rIdx },
                { x: 1, y: rIdx + 1 }
            ]
            setPixel(newImgData, 0, rIdx, avgPixels(imgData, leftIndices, [
                kernel[1], kernel[2], kernel[4], kernel[5], kernel[7], kernel[8]
            ]))
        }

        if (selection[rIdx * imgData.width + maxX]) {
            const rightIndices = [
                { x: maxX - 1, y: rIdx - 1 },
                { x: maxX - 1, y: rIdx },
                { x: maxX - 1, y: rIdx + 1 },
                { x: maxX, y: rIdx - 1 },
                { x: maxX, y: rIdx },
                { x: maxX, y: rIdx + 1 }
            ]
            setPixel(newImgData, maxX, rIdx, avgPixels(imgData, rightIndices, [
                kernel[0], kernel[1], kernel[3], kernel[4], kernel[6], kernel[7]
            ]))
        }
    }


    // middle part
    for (let rIdx = 1; rIdx < maxY; rIdx += 1) {
        for (let cIdx = 1; cIdx < maxX; cIdx += 1) {
            if (!selection[rIdx * imgData.width + cIdx]) {
                continue
            }

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
            setPixel(newImgData, cIdx, rIdx, avgPixels(imgData, indices, kernel))
        }
    }

    return newImgData
}
