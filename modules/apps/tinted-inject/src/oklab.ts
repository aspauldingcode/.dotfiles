/**
 * sRGB ↔ Oklab color-space conversion.
 *
 * This is Björn Ottosson's reference implementation from
 * https://bottosson.github.io/posts/oklab/, ported to TypeScript and
 * specialized for `[r, g, b]` triples in the canonical sRGB integer
 * range (0..255). It is the same conversion that
 * `vendor/lutgen-rs/crates/lib/src/interpolation/rbf.rs` calls into via
 * the upstream `oklab` Rust crate.
 *
 * Why Oklab and not plain sRGB / Lab:
 *   - Distances in Oklab approximate perceptual difference far better
 *     than sRGB Euclidean distance. Two pixels that look "equally
 *     dissimilar" to a human have approximately equal Oklab distance.
 *     This is what makes "any blue → palette blue" mappings actually
 *     match where humans would draw the boundary.
 *   - Oklab is computationally cheap (one 3x3 matmul + cbrt + another
 *     3x3 matmul, no iteration). Suitable for per-pixel use.
 */

export type Rgb = readonly [number, number, number] // each 0..255
export type Oklab = readonly [number, number, number] // L ∈ [0, 1], a/b ~ ±0.4

const SRGB_LINEAR_THRESHOLD = 0.04045
const LINEAR_SRGB_THRESHOLD = 0.0031308

function srgbChannelToLinear(value: number): number {
  const s = value / 255
  return s <= SRGB_LINEAR_THRESHOLD ? s / 12.92 : Math.pow((s + 0.055) / 1.055, 2.4)
}

function linearChannelToSrgb(value: number): number {
  const clamped = Math.max(0, Math.min(1, value))
  const c =
    clamped <= LINEAR_SRGB_THRESHOLD
      ? clamped * 12.92
      : 1.055 * Math.pow(clamped, 1 / 2.4) - 0.055
  return Math.round(c * 255)
}

export function srgbToOklab([r, g, b]: Rgb): Oklab {
  const lr = srgbChannelToLinear(r)
  const lg = srgbChannelToLinear(g)
  const lb = srgbChannelToLinear(b)

  const l = 0.4122214708 * lr + 0.5363325363 * lg + 0.0514459929 * lb
  const m = 0.2119034982 * lr + 0.6806995451 * lg + 0.1073969566 * lb
  const s = 0.0883024619 * lr + 0.2817188376 * lg + 0.6299787005 * lb

  const l_ = Math.cbrt(l)
  const m_ = Math.cbrt(m)
  const s_ = Math.cbrt(s)

  return [
    0.2104542553 * l_ + 0.7936177850 * m_ - 0.0040720468 * s_,
    1.9779984951 * l_ - 2.4285922050 * m_ + 0.4505937099 * s_,
    0.0259040371 * l_ + 0.7827717662 * m_ - 0.8086757660 * s_,
  ]
}

export function oklabToSrgb([L, a, b]: Oklab): Rgb {
  const l_ = L + 0.3963377774 * a + 0.2158037573 * b
  const m_ = L - 0.1055613458 * a - 0.0638541728 * b
  const s_ = L - 0.0894841775 * a - 1.2914855480 * b

  const l = l_ * l_ * l_
  const m = m_ * m_ * m_
  const s = s_ * s_ * s_

  const lr = +4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s
  const lg = -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s
  const lb = -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s

  return [linearChannelToSrgb(lr), linearChannelToSrgb(lg), linearChannelToSrgb(lb)]
}

/**
 * Parse a `#rrggbb` or `#rgb` hex string into an `Rgb` triple. Throws
 * `RangeError` on malformed input. We use this in the LUT layer to
 * decode Base16/Base24 palette slots, which are stored as hex strings.
 */
export function hexToRgb(hex: string): Rgb {
  const trimmed = hex.trim().replace(/^#/, '')
  if (trimmed.length === 3) {
    const r = parseInt(trimmed[0]! + trimmed[0]!, 16)
    const g = parseInt(trimmed[1]! + trimmed[1]!, 16)
    const b = parseInt(trimmed[2]! + trimmed[2]!, 16)
    if ([r, g, b].some((c) => Number.isNaN(c))) {
      throw new RangeError(`invalid hex color: ${hex}`)
    }
    return [r, g, b]
  }
  if (trimmed.length === 6) {
    const r = parseInt(trimmed.slice(0, 2), 16)
    const g = parseInt(trimmed.slice(2, 4), 16)
    const b = parseInt(trimmed.slice(4, 6), 16)
    if ([r, g, b].some((c) => Number.isNaN(c))) {
      throw new RangeError(`invalid hex color: ${hex}`)
    }
    return [r, g, b]
  }
  throw new RangeError(`hex color must be #rgb or #rrggbb: ${hex}`)
}

export function rgbToHex([r, g, b]: Rgb): string {
  const h = (c: number) => c.toString(16).padStart(2, '0')
  return `#${h(r)}${h(g)}${h(b)}`
}
