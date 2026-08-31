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
 * Palette-to-color lookup-table mapper. This is the in-browser port of
 * `vendor/lutgen-rs/crates/lib/src/interpolation/rbf.rs`'s Gaussian
 * RBF remapper. `gowall` ships an independent implementation of the
 * same idea in plain sRGB Go (see
 * `vendor/gowall/internal/backends/colorthief/haldClut/rbf.go`); we
 * follow lutgen-rs and run the math in OKLab so distances correspond
 * to perceived dissimilarity.
 *
 *     for each palette color p:
 *       distance² = ‖oklab(input) - oklab(p)‖²    (lum scaled)
 *       weight    = exp(-shape · distance²)
 *     output = Σ p·weight / Σ weight              (in Oklab)
 *
 * It produces "any blue → palette blue, any red → palette red"
 * behaviour: bright reds sit close to the palette's red slot in
 * Oklab, so their weight is dominated by that slot and the output
 * collapses onto it. Pixels that fall between two palette neighbours
 * smoothly blend (no posterization), so gradients keep looking like
 * gradients.
 */

/**
 * Build a `ColorMapper` for `palette` in Oklab space using the
 * Gaussian RBF described above. Returned mapper memoizes results so
 * the second mention of a color in a stylesheet is O(1).
 */
export function buildRbfMapper(
  palette: readonly Rgb[],
  options: Partial<LutOptions> = {},
): ColorMapper {
  assertPaletteNonEmpty(palette)
  const opts = { ...DEFAULT_LUT_OPTIONS, ...options }

  // Store palette colors un-scaled. The L axis is multiplied by
  // `lumFactor` only inside the distance computation — never in
  // the output reconstruction — so `lumFactor=0` (chroma-only
  // matching) doesn't cause `0/0` when re-scaling the result.
  const oklabPalette: Oklab[] = palette.map((rgb) => srgbToOklab(rgb))

  // 24-bit color space ⇒ 16M entries max, but in practice a typical
  // page touches a few hundred unique colors. The cache pays for
  // itself many times over and a Map keeps eviction trivial if we
  // ever need to bound memory.
  const cache = new Map<number, Rgb>()
  const key = (r: number, g: number, b: number) => (r << 16) | (g << 8) | b

  return function mapColor(rgb: Rgb): Rgb {
    const cacheKey = key(rgb[0], rgb[1], rgb[2])
    const hit = cache.get(cacheKey)
    if (hit) return hit

    const [L0, a0, b0] = srgbToOklab(rgb)
    const Lscaled = L0 * opts.lumFactor

    let numL = 0
    let numA = 0
    let numB = 0
    let denom = 0
    for (const [pL, pA, pB] of oklabPalette) {
      const dL = Lscaled - pL * opts.lumFactor
      const dA = a0 - pA
      const dB = b0 - pB
      const distSq = dL * dL + dA * dA + dB * dB
      const w = Math.exp(-opts.shape * distSq)
      numL += pL * w
      numA += pA * w
      numB += pB * w
      denom += w
    }

    if (denom === 0) {
      // Numerically every palette weight underflowed to zero (only
      // possible at shape ≫ 1000 with a far-out input). Fall back to
      // the input untouched — preferable to NaN'ing out as black.
      cache.set(cacheKey, rgb)
      return rgb
    }

    const outL = opts.preserveLuminance ? L0 : numL / denom
    const outA = numA / denom
    const outB = numB / denom
    const result = oklabToSrgb([outL, outA, outB])
    cache.set(cacheKey, result)
    return result
  }
}
