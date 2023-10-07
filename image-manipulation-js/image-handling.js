export function loadImg(url) {
  return new Promise(resolve => {
    let img = new Image()
    img.crossOrigin = 'Anonymous'
    img.onload = () => resolve(img)
    img.src = url
  })
}

export function drawImageToCanvas(canvas, img) {
  const context = canvas.getContext('2d')
  canvas.width = img.width
  canvas.height = img.height
  if (img instanceof ImageData) {
    context.putImageData(img, 0, 0)
  } else {
    context.drawImage(img, 0, 0)
  }
}
