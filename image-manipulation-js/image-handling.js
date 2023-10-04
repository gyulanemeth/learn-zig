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
  canvas.width = img.naturalWidth
  canvas.height = img.naturalHeight
  context.drawImage(img, 0, 0)
}
