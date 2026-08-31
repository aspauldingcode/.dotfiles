import {
  oklabToSrgb,
  srgbToOklab,
  type Oklab,
  type Rgb,
} from '../oklab'
import {
  assertPaletteNonEmpty,
  DEFAULT_LUT_OPTIONS,
  type ColorMapper,
  type LutOptions,
} from './options'

/**
 * Hard quantizing palette mapper. Faithful port of
 * `vendor/lutgen-rs/crates/lib/src/interpolation/nearest_neighbor.rs`.
 * Every input sRGB triple is mapped to exactly one palette slot:
 *
 *   1. Convert input to OKLab.
 *   2. Find the palette slot with the smallest squared OKLab
 *      distance (with the L term scaled by `lumFactor` to bring the
 *      perceptual L axis closer to chroma weight).
 *   3. Either return the palette's sRGB triple verbatim, or — when
 *      `preserveLuminance` is true — keep the input's L and only
 *      take (a, b) from the palette slot.
 *
 * Linear scan over the palette is fine: Base16 has 16 colors,
 * Base24 has 24, both well below the threshold where a KD-tree pays
 * for itself in JavaScript. Lutgen-rs uses a `kiddo::KdTree` because
 * it operates on 17³+ HALD lattices; we don't need it here.
 *
 * Use this algorithm when you want guaranteed palette colors: every
 * pixel of the rendered page is exactly one of the configured 16/24
 * slots, no blending. The trade-off is banding — gradients become
 * step-wise. RBF (the default) avoids that at the cost of producing
 * intermediate colors that are not literally in the palette.
 */
export function buildNearestMapper(
  palette: readonly Rgb[],
  options: Partial<LutOptions> = {},
): ColorMapper {
  assertPaletteNonEmpty(palette)
  const opts = { ...DEFAULT_LUT_OPTIONS, ...options }

  const oklabPalette: Oklab[] = palette.map((rgb) => srgbToOklab(rgb))

  const cache = new Map<number, Rgb>()
  const key = (r: number, g: number, b: number) => (r << 16) | (g << 8) | b

  return function mapColor(rgb: Rgb): Rgb {
    const cacheKey = key(rgb[0], rgb[1], rgb[2])
    const hit = cache.get(cacheKey)
    if (hit) return hit

    const [L0, a0, b0] = srgbToOklab(rgb)
    const Lscaled = L0 * opts.lumFactor

    let bestIdx = 0
    let bestD = Infinity
    for (let i = 0; i < oklabPalette.length; i += 1) {
      const slot = oklabPalette[i]!
      const dL = Lscaled - slot[0] * opts.lumFactor
      const dA = a0 - slot[1]
      const dB = b0 - slot[2]
      const d = dL * dL + dA * dA + dB * dB
      if (d < bestD) {
        bestD = d
        bestIdx = i
      }
    }

    let result: Rgb
    if (opts.preserveLuminance) {
      const slot = oklabPalette[bestIdx]!
      result = oklabToSrgb([L0, slot[1], slot[2]])
    } else {
      // Copy the palette's sRGB triple verbatim — this is the whole
      // point of nearest-neighbor mode. Wrap in a fresh tuple so
      // callers can't mutate the palette through the returned value.
      const p = palette[bestIdx]!
      result = [p[0], p[1], p[2]]
    }
    cache.set(cacheKey, result)
    return result
  }
}
