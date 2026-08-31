import { hexToRgb, rgbToHex, type Rgb } from '../oklab'
import { buildBlurMapper } from './blur'
import { buildNearestMapper } from './nearest'
import {
  DEFAULT_RECOLOR,
  type ColorMapper,
  type LutOptions,
  type RecolorAlgorithm,
  type RecolorSettings,
} from './options'
import { buildRbfMapper } from './rbf'

export {
  DEFAULT_LUT_OPTIONS,
  DEFAULT_RECOLOR,
  type ColorMapper,
  type LutOptions,
  type RecolorAlgorithm,
  type RecolorSettings,
} from './options'
export { buildRbfMapper } from './rbf'
export { buildNearestMapper } from './nearest'
export { buildBlurMapper } from './blur'

export const buildLut = buildRbfMapper

const BASE16_SLOTS = [
  'base00',
  'base01',
  'base02',
  'base03',
  'base04',
  'base05',
  'base06',
  'base07',
  'base08',
  'base09',
  'base0A',
  'base0B',
  'base0C',
  'base0D',
  'base0E',
  'base0F',
] as const

export function paletteColorsForLut(
  palette: Record<string, string> | readonly string[],
): Rgb[] {
  if (Array.isArray(palette)) {
    return palette.map((hex) => hexToRgb(hex))
  }
  return BASE16_SLOTS.map((slot) => hexToRgb(palette[slot] ?? '#000000'))
}

export function buildColorMapper(
  palette: readonly Rgb[],
  opts: RecolorSettings = DEFAULT_RECOLOR,
): ColorMapper {
  switch (opts.algorithm) {
    case 'nearest':
      return buildNearestMapper(palette, lutOptionsFromRecolor(opts))
    case 'gaussian-blur':
      return buildBlurMapper(palette, {
        ...lutOptionsFromRecolor(opts),
        radius: opts.radius,
        level: opts.level,
      })
    case 'rbf':
    default:
      return buildRbfMapper(palette, lutOptionsFromRecolor(opts))
  }
}

function lutOptionsFromRecolor(opts: RecolorSettings): LutOptions {
  return {
    shape: opts.shape,
    lumFactor: opts.lumFactor,
    preserveLuminance: opts.preserveLuminance,
  }
}

export function buildHexMapper(
  palette: readonly Rgb[],
  options: Partial<LutOptions> = {},
): (hex: string) => string {
  const inner = buildRbfMapper(palette, options)
  return (hex) => rgbToHex(inner(hexToRgb(hex)))
}
