import {
  oklabToSrgb,
  srgbToOklab,
  type Rgb,
} from '../oklab'
import {
  assertPaletteNonEmpty,
  DEFAULT_LUT_OPTIONS,
  type ColorMapper,
  type LutOptions,
} from './options'

/**
 * Gaussian Blur HALD CLUT mapper. TypeScript port of
 * `vendor/lutgen-rs/crates/lib/src/interpolation/gaussian_blur.rs`.
 *
 * Algorithm (mirrors lutgen-rs's `GaussianBlurRemapper`):
 *
 *   1. Build a 3D OKLab grid of side `size = level²` cells. For each
 *      cell (r, g, b) in identity-CLUT order, convert the cell's
 *      reference sRGB to OKLab and snap to the nearest palette slot
 *      (with a hint from spatial coherence so most cells skip the
 *      full scan).
 *   2. Apply three separable Gaussian blur passes along the inner
 *      axis, rotating dimensions between passes ([R][G][B] →
 *      [G][B][R] → [B][R][G] → [R][G][B]) for cache locality. Kernel
 *      width is 2·⌈3·radius⌉+1.
 *   3. Convert the blurred OKLab grid back to sRGB once.
 *
 * The resulting LUT is cached at module scope, keyed by the palette
 * fingerprint plus the option set, so subsequent calls with the same
 * arguments return a `ColorMapper` backed by the same precomputed
 * grid (typical workload: one build per `engine.apply` per page,
 * shared across thousands of color lookups).
 *
 * Lookup uses nearest-cell quantization (round each input channel
 * onto the lattice). Trilinear interpolation would be faithful to
 * lutgen-rs's `correct_image`, but at `level=6` (size=36) the visual
 * difference is small and nearest-cell is markedly cheaper to
 * implement and validate. We list trilinear as future work in
 * `docs/RECOLORING_PIPELINE.md`.
 */

export interface BlurOptions extends LutOptions {
  /**
   * Gaussian sigma applied during the three separable convolution
   * passes that smooth the precomputed HALD CLUT. lutgen-rs's CLI
   * default is 8.0; values above ~16 turn the LUT into a uniform
   * blur and lose palette identity.
   */
  radius: number
  /**
   * HALD CLUT level. The lattice has S = level² cells per axis. 4..8
   * is the usable range; 6 is a good default (S=36, 36³ ≈ 46k cells
   * × 3 bytes ≈ 140 KB per palette, build cost is a few hundred
   * milliseconds).
   */
  level: number
}

/**
 * Default blur knobs. Inherits from `DEFAULT_LUT_OPTIONS` and adds
 * `radius` / `level` to match lutgen-rs's CLI defaults (with the
 * level shrunk from 10 to 6 to keep the per-palette build under a
 * megabyte and well below 1s on typical hardware).
 */
export const DEFAULT_BLUR_OPTIONS: BlurOptions = {
  ...DEFAULT_LUT_OPTIONS,
  radius: 8.0,
  level: 6,
}

/**
 * Module-scoped HALD cache. Builds are expensive (a level-6 lattice
 * ≈ 46k cells × NN + 3 blur passes ≈ a few hundred milliseconds in
 * pure JS) and a tab typically calls `engine.apply` multiple times
 * with the same (palette, options) tuple. Cache hit returns the
 * exact same `Hald` object, which the new mapper memoizes
 * per-input-color on top.
 */
const HALD_CACHE = new Map<string, Hald>()

/**
 * Build a `ColorMapper` that runs every input color through the
 * Gaussian Blur HALD CLUT. Wraps the underlying numeric `Hald` in a
 * per-call cache so repeated lookups of the same input color are
 * O(1).
 */
export function buildBlurMapper(
  palette: readonly Rgb[],
  options: Partial<BlurOptions> = {},
): ColorMapper {
  assertPaletteNonEmpty(palette)
  const opts = { ...DEFAULT_BLUR_OPTIONS, ...options }
  const hald = getOrBuildHald(palette, opts)
  return makeMapper(hald)
}

/**
 * Internal accessor. Same arguments produce the same `Hald` object
 * (cache hit), which makes "build twice → same reference"
 * memoization observable in tests.
 */
export function getOrBuildHald(
  palette: readonly Rgb[],
  opts: BlurOptions,
): Hald {
  const k = cacheKey(palette, opts)
  const hit = HALD_CACHE.get(k)
  if (hit) return hit
  const built = buildHald(palette, opts)
  HALD_CACHE.set(k, built)
  return built
}

/**
 * Test-only escape hatch for clearing the HALD cache between runs.
 * Production code never needs this; the cache is bounded by the
 * number of (palette, opts) tuples a single browser session
 * encounters, which is tiny.
 */
export function _resetBlurCache(): void {
  HALD_CACHE.clear()
}

/**
 * Precomputed HALD CLUT. `lut` is an interleaved `Uint8Array` of
 * `size^3 * 3` bytes in (r, g, b) cell order — same layout as the
 * input grid before conversion. `size` is `level²`.
 */
export interface Hald {
  size: number
  lut: Uint8Array
}

function buildHald(palette: readonly Rgb[], opts: BlurOptions): Hald {
  const size = opts.level * opts.level
  const nCells = size * size * size
  const channels = opts.preserveLuminance ? 2 : 3
  const scale = 255 / (size - 1)

  const paletteOklab = palette.map((rgb) => {
    const [L, a, b] = srgbToOklab(rgb)
    return new Float32Array([L * opts.lumFactor, a, b])
  })

  // Build NN LUT in OKLab space. Spatial-coherence hint: along the
  // innermost axis (b) consecutive cells are very similar in OKLab,
  // so the previous nearest is almost always still the best.
  const colors = new Float32Array(nCells * channels)
  const step = 1 / size
  const thresholdSq = step * step * 0.5

  let hint = 0
  let outIdx = 0
  for (let r = 0; r < size; r += 1) {
    const rf = Math.round(r * scale)
    for (let g = 0; g < size; g += 1) {
      const gf = Math.round(g * scale)
      for (let b = 0; b < size; b += 1) {
        const bf = Math.round(b * scale)
        const [L, a, ob] = srgbToOklab([rf, gf, bf])
        const probe = [L * opts.lumFactor, a, ob] as const
        const nearest = findNearestWithHint(
          paletteOklab,
          probe,
          hint,
          thresholdSq,
        )
        hint = nearest
        const target = paletteOklab[nearest]!
        if (opts.preserveLuminance) {
          colors[outIdx] = target[1]!
          colors[outIdx + 1] = target[2]!
        } else {
          // Store the original (un-scaled) L so the inverse conversion
          // can reach it directly. lutgen-rs achieves the same by
          // dividing by `lumFactor` at write time.
          colors[outIdx] = (target[0]! / opts.lumFactor)
          colors[outIdx + 1] = target[1]!
          colors[outIdx + 2] = target[2]!
        }
        outIdx += channels
      }
    }
  }

  // Three separable Gaussian blur passes with dimension rotation in
  // between. Rotation makes the previously-outer axis the new inner
  // axis so the blur loop always walks contiguous memory.
  const buf2 = new Float32Array(nCells * channels)
  const kernel = buildKernel(opts.radius)
  const half = (kernel.length - 1) >> 1
  const max = size - 1

  // Pass 1: blur along B (innermost in [R][G][B] layout)
  blurInner(colors, buf2, size, channels, kernel, half, max)
  // Rotate [R][G][B] -> [G][B][R]
  rotateDims(buf2, colors, size, channels)
  // Pass 2: blur along R (now innermost)
  blurInner(colors, buf2, size, channels, kernel, half, max)
  // Rotate [G][B][R] -> [B][R][G]
  rotateDims(buf2, colors, size, channels)
  // Pass 3: blur along G (now innermost)
  blurInner(colors, buf2, size, channels, kernel, half, max)
  // Rotate [B][R][G] -> [R][G][B], back to canonical layout
  rotateDims(buf2, colors, size, channels)

  // Convert blurred OKLab grid back to sRGB.
  const lut = new Uint8Array(nCells * 3)
  let inIdx = 0
  let lutIdx = 0
  for (let r = 0; r < size; r += 1) {
    for (let g = 0; g < size; g += 1) {
      for (let b = 0; b < size; b += 1) {
        let outRgb: Rgb
        if (opts.preserveLuminance) {
          // Recover L from this cell's reference sRGB so we keep the
          // input pixel's luminance rather than the palette's.
          const rf = Math.round(r * scale)
          const gf = Math.round(g * scale)
          const bf = Math.round(b * scale)
          const [L] = srgbToOklab([rf, gf, bf])
          outRgb = oklabToSrgb([L, colors[inIdx]!, colors[inIdx + 1]!])
        } else {
          outRgb = oklabToSrgb([
            colors[inIdx]!,
            colors[inIdx + 1]!,
            colors[inIdx + 2]!,
          ])
        }
        lut[lutIdx] = outRgb[0]
        lut[lutIdx + 1] = outRgb[1]
        lut[lutIdx + 2] = outRgb[2]
        inIdx += channels
        lutIdx += 3
      }
    }
  }

  return { size, lut }
}

/**
 * Build a normalized 1D Gaussian kernel of width 2·⌈3·radius⌉+1.
 * Mirrors lutgen-rs's `build_kernel`.
 */
function buildKernel(radius: number): Float32Array {
  const half = Math.max(0, Math.ceil(radius * 3))
  const twoSigmaSq = 2 * radius * radius
  const len = 2 * half + 1
  const kernel = new Float32Array(len)
  // When radius is 0 the kernel collapses to a single 1.0 sample
  // (no-op blur). Guard against the divide-by-zero in `exp`.
  if (twoSigmaSq === 0) {
    kernel[half] = 1
    return kernel
  }
  let sum = 0
  for (let i = 0; i < len; i += 1) {
    const offset = i - half
    const w = Math.exp(-(offset * offset) / twoSigmaSq)
    kernel[i] = w
    sum += w
  }
  for (let i = 0; i < len; i += 1) kernel[i]! /= sum
  return kernel
}

/**
 * 1D Gaussian convolution along the innermost (contiguous) axis with
 * `clamp` edge handling. Mirrors lutgen-rs's `blur_inner`.
 */
function blurInner(
  src: Float32Array,
  dst: Float32Array,
  size: number,
  channels: number,
  kernel: Float32Array,
  half: number,
  max: number,
): void {
  const rowLen = size * channels
  for (let outer = 0; outer < size; outer += 1) {
    for (let mid = 0; mid < size; mid += 1) {
      const rowBase = (outer * size + mid) * rowLen
      for (let inner = 0; inner < size; inner += 1) {
        const outBase = rowBase + inner * channels
        for (let c = 0; c < channels; c += 1) {
          let sum = 0
          for (let ki = 0; ki < kernel.length; ki += 1) {
            let innerSrc = inner + ki - half
            if (innerSrc < 0) innerSrc = 0
            else if (innerSrc > max) innerSrc = max
            sum += kernel[ki]! * src[rowBase + innerSrc * channels + c]!
          }
          dst[outBase + c] = sum
        }
      }
    }
  }
}

/**
 * Rotate a 3D buffer's axes: [a][b][c] → [b][c][a]. Mirrors
 * lutgen-rs's `rotate_dims`.
 */
function rotateDims(
  src: Float32Array,
  dst: Float32Array,
  size: number,
  channels: number,
): void {
  for (let a = 0; a < size; a += 1) {
    for (let b = 0; b < size; b += 1) {
      for (let c = 0; c < size; c += 1) {
        const srcIdx = ((a * size + b) * size + c) * channels
        const dstIdx = ((b * size + c) * size + a) * channels
        for (let ch = 0; ch < channels; ch += 1) {
          dst[dstIdx + ch] = src[srcIdx + ch]!
        }
      }
    }
  }
}

/**
 * Find the palette slot whose squared OKLab distance to `color` is
 * smallest, using `hint` (the previous slot index) for spatial
 * coherence: if the hint's distance is below `thresholdSq` we accept
 * it without scanning. Mirrors lutgen-rs's `find_nearest_with_hint`.
 */
function findNearestWithHint(
  palette: ReadonlyArray<Float32Array>,
  color: readonly [number, number, number],
  hint: number,
  thresholdSq: number,
): number {
  const hintEntry = palette[hint]!
  const hintDist = sqDist3(color, hintEntry)
  if (hintDist < thresholdSq) return hint

  let bestIdx = hint
  let bestDist = hintDist
  for (let i = 0; i < palette.length; i += 1) {
    if (i === hint) continue
    const d = sqDist3(color, palette[i]!)
    if (d < bestDist) {
      bestDist = d
      bestIdx = i
    }
  }
  return bestIdx
}

function sqDist3(
  a: readonly [number, number, number],
  b: Float32Array,
): number {
  const dl = a[0] - b[0]!
  const da = a[1] - b[1]!
  const db = a[2] - b[2]!
  return dl * dl + da * da + db * db
}

/**
 * Wrap a precomputed HALD in a per-color memoizing mapper. Cache
 * keys are 24-bit packed sRGB; lookup picks the nearest lattice
 * cell.
 */
function makeMapper(hald: Hald): ColorMapper {
  const { size, lut } = hald
  // Multiply by `size - 1` then divide by 255 to map an sRGB byte
  // onto a `[0, size-1]` lattice index. Round to nearest cell.
  const scale = (size - 1) / 255
  const cache = new Map<number, Rgb>()
  const key = (r: number, g: number, b: number) => (r << 16) | (g << 8) | b
  return function mapColor(rgb: Rgb): Rgb {
    const k = key(rgb[0], rgb[1], rgb[2])
    const hit = cache.get(k)
    if (hit) return hit
    const r = Math.round(rgb[0] * scale)
    const g = Math.round(rgb[1] * scale)
    const b = Math.round(rgb[2] * scale)
    const cellIdx = (r * size + g) * size + b
    const off = cellIdx * 3
    const out: Rgb = [lut[off]!, lut[off + 1]!, lut[off + 2]!]
    cache.set(k, out)
    return out
  }
}

/**
 * Stable cache key. Uses the palette's hex fingerprint plus a
 * deterministic option-set serialization. Two builders called with
 * the same arguments share the same HALD by reference.
 */
function cacheKey(palette: readonly Rgb[], opts: BlurOptions): string {
  const sig = palette
    .map((p) => `${p[0]},${p[1]},${p[2]}`)
    .join('|')
  return `${sig}::${opts.radius}|${opts.level}|${opts.lumFactor}|${opts.preserveLuminance ? 1 : 0}`
}
