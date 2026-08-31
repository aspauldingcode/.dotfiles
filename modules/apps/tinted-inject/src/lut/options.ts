import type { Rgb } from '../oklab'

/**
 * Public types that every LUT implementation in this directory shares.
 * These are intentionally split out from the algorithm modules so the
 * dispatcher (`./index.ts`) can re-export them alongside the algorithm
 * builders without producing a circular import.
 */

/**
 * The runtime mapper signature: take an sRGB triple and return the
 * remapped sRGB triple. Used uniformly across the three algorithms
 * (RBF, nearest neighbor, Gaussian blur). Implementations are free to
 * memoize internally — `LutRewriter` calls them once per unique color
 * token in the page's CSS, but a cache makes the second mention of a
 * color free.
 */
export type ColorMapper = (rgb: Rgb) => Rgb

/**
 * Knobs accepted by every algorithm. Individual algorithms ignore
 * fields that don't apply to them (e.g. nearest-neighbor doesn't read
 * `shape` or `radius`); the structure is uniform so the engine can
 * pass the same options bag through without branching on algorithm.
 *
 * Defaults match the previous `lut.ts` behavior exactly so existing
 * call sites that don't pass options keep producing identical output.
 */
export interface LutOptions {
  /**
   * Gaussian RBF shape parameter. Larger → sharper snap to nearest
   * palette color; smaller → smoother gradients but more washed-out
   * tint. Lutgen's default is 128. Used by the `rbf` algorithm only.
   */
  shape: number

  /**
   * Multiplies the L channel before computing distances in OKLab.
   * The L axis is wide compared to the (a, b) chroma axes, so a
   * strict 1.0 weight makes the L term dominate and any
   * sufficiently-dark or sufficiently-light pixel gets pulled to the
   * nearest-luminance palette slot — even when a saturated accent at
   * a different lightness is plainly the more appropriate match by
   * hue.
   *
   * Default 0.5 — chroma carries twice the weight of luminance in
   * distance computations. Used by every algorithm.
   */
  lumFactor: number

  /**
   * When true, keep the input pixel's luminance and only swap chroma.
   *
   * Setting it to `false` is what makes the output ACTUALLY a palette
   * color: white-ish inputs collapse to the palette's brightest
   * neutral, black-ish inputs to the darkest neutral, and saturated
   * accents land on the palette's accent slots. The Base16 / Base24
   * spec is intentionally designed with full L coverage across its
   * neutral slots (`base00..base07`) precisely so this works.
   */
  preserveLuminance: boolean
}

/**
 * The defaults inherited from the original `lut.ts`. They survived a
 * detailed empirical triangulation against many real palettes (see
 * `docs/RECOLORING_PIPELINE.md`); changing them silently breaks the
 * "any blue → palette blue, any red → palette red" property.
 */
export const DEFAULT_LUT_OPTIONS: LutOptions = {
  shape: 128,
  lumFactor: 0.5,
  preserveLuminance: false,
}

/**
 * Throws if `palette` is empty. All three algorithms call this from
 * their builders so the failure mode is identical.
 */
export function assertPaletteNonEmpty(palette: readonly Rgb[]): void {
  if (palette.length === 0) {
    throw new RangeError('LUT palette must contain at least one color')
  }
}

/** Matches TintedBrowse `lib/config/schema.ts` — same defaults, same knobs. */
export type RecolorAlgorithm = 'rbf' | 'nearest' | 'gaussian-blur'

export interface RecolorSettings {
  algorithm: RecolorAlgorithm
  shape: number
  nearest: number
  radius: number
  level: number
  lumFactor: number
  preserveLuminance: boolean
}

export const DEFAULT_RECOLOR: RecolorSettings = {
  algorithm: 'rbf',
  shape: 128,
  nearest: 0,
  radius: 8.0,
  level: 6,
  lumFactor: 0.5,
  preserveLuminance: false,
}
