const radInDeg = 180 / Math.PI

export function rgbToHsl ({ r, g, b, a }) {
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

export function hslToRgb({ h, s, l, a }) {
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
