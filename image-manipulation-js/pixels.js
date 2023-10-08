function getPixelIndices(width, x, y) {
  const rIdx = y * (width * 4) + x * 4
  const gIdx = rIdx + 1
  const bIdx = rIdx + 2
  const aIdx = rIdx + 3

  return [ rIdx, gIdx, bIdx, aIdx ]
}

export function getPixel(imgData, x, y) {
  const [ rIdx, gIdx, bIdx, aIdx ] = getPixelIndices(imgData.width, x, y)

  return {
      r: imgData.data[rIdx],
      g: imgData.data[gIdx],
      b: imgData.data[bIdx],
      a: imgData.data[aIdx]
  }
}

export function setPixel(imgData, x, y, { r, g, b, a }) {
  const [ rIdx, gIdx, bIdx, aIdx ] = getPixelIndices(imgData.width, x, y)

  imgData.data[rIdx] = r
  imgData.data[gIdx] = g
  imgData.data[bIdx] = b
  imgData.data[aIdx] = a
}
