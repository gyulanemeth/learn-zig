import { rgbToHsl, hslToRgb } from "./convert.js"

export function addHslaToSelection(imgData, selection, hslaDiff) {
  const newImgData = new ImageData(imgData.width, imgData.height)
  for (let idx = 0; idx < imgData.data.length; idx += 4) {
      const coordIdx = idx / 4

      const r = imgData.data[idx]
      const g = imgData.data[idx + 1]
      const b = imgData.data[idx + 2]
      const a = imgData.data[idx + 3]

      if (selection[coordIdx] != 1) {
        newImgData.data[idx] = r
        newImgData.data[idx + 1] = g
        newImgData.data[idx + 2] = b
        newImgData.data[idx + 3] = a
        continue
      }

      const hsla = rgbToHsl({ r, g, b, a })
      hsla.h += hslaDiff.h
      hsla.s += hslaDiff.s
      hsla.l += hslaDiff.l
      hsla.a += hslaDiff.a

      if (hsla.h < 0) {
          hsla.h += 360
      }

      if (hsla.h >= 360) {
          hsla.h -= 360
      }

      if (hsla.l > 1) {
          hsla.l = 1
      }

      if (hsla.l < 0) {
          hsla.l = 0
      }

      if (hsla.s > 1) {
          hsla.s = 1
      }

      if (hsla.s < 0) {
          hsla.s = 0
      }

      if (hsla.a < 0) {
          hsla.a = 0
      }

      if (hsla.a > 255) {
          hsla.a = 255
      }

      const newRgba = hslToRgb(hsla)
      newImgData.data[idx] = newRgba.r
      newImgData.data[idx + 1] = newRgba.g
      newImgData.data[idx + 2] = newRgba.b
      newImgData.data[idx + 3] = 255 // temp
  }

  return newImgData
}
