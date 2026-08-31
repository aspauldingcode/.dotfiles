import type { Rgb } from './oklab'

/**
 * Parse / serialize / find CSS color tokens.
 *
 * Used by the LUT rewriter: when given a CSS declaration value like
 * `"1px solid #ff0000"` or `"linear-gradient(to right, red, blue)"`,
 * we want to find every color sub-token, run it through the Oklab
 * Gaussian RBF mapper, and re-serialize the value with the mapped
 * colors substituted in place. The non-color parts of the value
 * (lengths, gradient stops percentages, image URLs, etc.) must
 * round-trip byte-identical.
 *
 * What is supported:
 *   - Hex: `#rgb`, `#rgba`, `#rrggbb`, `#rrggbbaa` — alpha is
 *     preserved in the output.
 *   - Functional: `rgb(r, g, b)`, `rgba(r, g, b, a)` with comma or
 *     whitespace-and-slash syntax (CSS Color 4). Channels accept
 *     0..255 integers, 0..255 decimals, or 0..100% percentages.
 *   - Named: the 16 CSS Level 1 / Level 2 keywords (transparent,
 *     red, blue, …) plus a small extension list. We deliberately do
 *     NOT inflate this to all ~150 X11 names — popular sites stick to
 *     hex / rgb in production CSS, and a 150-entry table balloons the
 *     content-script bundle for diminishing returns. Sites using
 *     uncommon named colors will see those go unmapped (rendered as
 *     authored), which is a graceful degradation.
 *
 * What is intentionally NOT supported (yet):
 *   - `hsl()` / `hsla()` — most production CSS is hex/rgb; HSL adds
 *     non-trivial parsing overhead. To revisit if the parity matrix
 *     shows real-world hits.
 *   - `lab()`, `lch()`, `oklch()`, `color()` — CSS Color 4 wide-gamut
 *     functions. Same reasoning: rare in shipped CSS today.
 *   - `color-mix()` — recursively contains other colors. Out of
 *     scope for the first cut.
 */

/** A parsed color, plus the original token's exact text (for replace-in-place). */
export interface ParsedColor {
  rgb: Rgb
  /** Alpha in [0, 1]. `undefined` when the source had no alpha component. */
  alpha?: number
  /** The exact substring that was matched, used to splice the value back together. */
  raw: string
  /** Where in the source string this token started. */
  start: number
  /** One past where this token ends in the source string. */
  end: number
  /** Which serialization to round-trip back into (preserve user intent). */
  format: 'hex' | 'rgb' | 'named'
}

const HEX_RE = /#[0-9a-fA-F]{3,8}\b/g
// `rgb(0 0 0 / 0.5)` and `rgb(0, 0, 0, 0.5)` both legal. Tolerate
// either separator and accept percent / number for channels.
const RGB_RE =
  /\brgba?\(\s*([+-]?\d*\.?\d+%?)\s*[ ,]\s*([+-]?\d*\.?\d+%?)\s*[ ,]\s*([+-]?\d*\.?\d+%?)\s*(?:[\/,]\s*([+-]?\d*\.?\d+%?))?\s*\)/g

const NAMED_COLORS: Record<string, Rgb> = {
  black: [0, 0, 0],
  silver: [192, 192, 192],
  gray: [128, 128, 128],
  grey: [128, 128, 128],
  white: [255, 255, 255],
  maroon: [128, 0, 0],
  red: [255, 0, 0],
  purple: [128, 0, 128],
  fuchsia: [255, 0, 255],
  magenta: [255, 0, 255],
  green: [0, 128, 0],
  lime: [0, 255, 0],
  olive: [128, 128, 0],
  yellow: [255, 255, 0],
  navy: [0, 0, 128],
  blue: [0, 0, 255],
  teal: [0, 128, 128],
  aqua: [0, 255, 255],
  cyan: [0, 255, 255],
  orange: [255, 165, 0],
  pink: [255, 192, 203],
  brown: [165, 42, 42],
  // Extras that are common in real stylesheets:
  azure: [240, 255, 255],
  beige: [245, 245, 220],
  ivory: [255, 255, 240],
  khaki: [240, 230, 140],
  salmon: [250, 128, 114],
  tan: [210, 180, 140],
  violet: [238, 130, 238],
  indigo: [75, 0, 130],
  gold: [255, 215, 0],
  coral: [255, 127, 80],
  crimson: [220, 20, 60],
  turquoise: [64, 224, 208],
  // CSS-special: `currentColor` and `inherit` aren't actual color
  // values — we let them pass through untouched.
}
// Compiled once for fast `\b(red|blue|...)\b` matching.
const NAMED_RE = new RegExp(
  `\\b(${Object.keys(NAMED_COLORS).join('|')})\\b`,
  'gi',
)

function clampChannel(value: string): number {
  if (value.endsWith('%')) {
    const pct = parseFloat(value.slice(0, -1))
    return Math.max(0, Math.min(255, Math.round((pct / 100) * 255)))
  }
  return Math.max(0, Math.min(255, Math.round(parseFloat(value))))
}

function clampAlpha(value: string | undefined): number | undefined {
  if (value === undefined) return undefined
  if (value.endsWith('%')) {
    return Math.max(0, Math.min(1, parseFloat(value.slice(0, -1)) / 100))
  }
  return Math.max(0, Math.min(1, parseFloat(value)))
}

function parseHex(token: string): Pick<ParsedColor, 'rgb' | 'alpha'> | null {
  const h = token.startsWith('#') ? token.slice(1) : token
  switch (h.length) {
    case 3:
      return {
        rgb: [
          parseInt(h[0]! + h[0]!, 16),
          parseInt(h[1]! + h[1]!, 16),
          parseInt(h[2]! + h[2]!, 16),
        ],
      }
    case 4: {
      const a = parseInt(h[3]! + h[3]!, 16) / 255
      return {
        rgb: [
          parseInt(h[0]! + h[0]!, 16),
          parseInt(h[1]! + h[1]!, 16),
          parseInt(h[2]! + h[2]!, 16),
        ],
        alpha: a,
      }
    }
    case 6:
      return {
        rgb: [
          parseInt(h.slice(0, 2), 16),
          parseInt(h.slice(2, 4), 16),
          parseInt(h.slice(4, 6), 16),
        ],
      }
    case 8: {
      const a = parseInt(h.slice(6, 8), 16) / 255
      return {
        rgb: [
          parseInt(h.slice(0, 2), 16),
          parseInt(h.slice(2, 4), 16),
          parseInt(h.slice(4, 6), 16),
        ],
        alpha: a,
      }
    }
    default:
      return null
  }
}

/** Find every color token in `value`, in left-to-right source order. */
export function findColorTokens(value: string): ParsedColor[] {
  const out: ParsedColor[] = []

  HEX_RE.lastIndex = 0
  for (let m = HEX_RE.exec(value); m !== null; m = HEX_RE.exec(value)) {
    const parsed = parseHex(m[0])
    if (!parsed) continue
    out.push({
      ...parsed,
      raw: m[0],
      start: m.index,
      end: m.index + m[0].length,
      format: 'hex',
    })
  }

  RGB_RE.lastIndex = 0
  for (let m = RGB_RE.exec(value); m !== null; m = RGB_RE.exec(value)) {
    const [, r, g, b, a] = m
    if (r === undefined || g === undefined || b === undefined) continue
    out.push({
      rgb: [clampChannel(r), clampChannel(g), clampChannel(b)],
      alpha: clampAlpha(a),
      raw: m[0],
      start: m.index,
      end: m.index + m[0].length,
      format: 'rgb',
    })
  }

  NAMED_RE.lastIndex = 0
  for (let m = NAMED_RE.exec(value); m !== null; m = NAMED_RE.exec(value)) {
    const named = NAMED_COLORS[m[0].toLowerCase()]
    if (!named) continue
    // Skip false positives: a "red" inside `linear-gradient(red, blue)`
    // is fine but `border` / `solid` etc. aren't named colors. Our
    // regex already restricts to the keyword list, so any whole-word
    // match is intentional.
    out.push({
      rgb: named,
      raw: m[0],
      start: m.index,
      end: m.index + m[0].length,
      format: 'named',
    })
  }

  // Stable order by start position so splice-in-place is unambiguous.
  // When two regexes match the same offset (shouldn't happen given
  // the regex guards) the first-emitted wins.
  out.sort((a, b) => a.start - b.start)
  return dedupeOverlaps(out)
}

/**
 * If two matches overlap (e.g. `#ff0000` vs `0` digits inside it),
 * the earlier-starting / longer match wins. This protects against
 * e.g. a hex color being also matched by a stray named-color regex
 * fragment (won't happen with the current regex, but defensive).
 */
function dedupeOverlaps(tokens: ParsedColor[]): ParsedColor[] {
  if (tokens.length < 2) return tokens
  const out: ParsedColor[] = []
  let lastEnd = -1
  for (const t of tokens) {
    if (t.start < lastEnd) continue
    out.push(t)
    lastEnd = t.end
  }
  return out
}

function toHex2(n: number): string {
  return Math.max(0, Math.min(255, n | 0)).toString(16).padStart(2, '0')
}

/**
 * Format a color back into a CSS string in `format`. When the source
 * had alpha, `format='hex'` produces `#rrggbbaa` and `format='rgb'`
 * produces `rgba(...)`. Named-color sources are re-emitted as `#hex`
 * because we have no inverse name lookup.
 */
export function serializeColor(
  rgb: Rgb,
  alpha: number | undefined,
  format: ParsedColor['format'],
): string {
  if (format === 'rgb') {
    if (alpha !== undefined && alpha < 1) {
      return `rgba(${rgb[0]}, ${rgb[1]}, ${rgb[2]}, ${
        Math.round(alpha * 1000) / 1000
      })`
    }
    return `rgb(${rgb[0]}, ${rgb[1]}, ${rgb[2]})`
  }
  // hex / named both serialize to hex
  const base = `#${toHex2(rgb[0])}${toHex2(rgb[1])}${toHex2(rgb[2])}`
  if (alpha !== undefined && alpha < 1) {
    return `${base}${toHex2(Math.round(alpha * 255))}`
  }
  return base
}

/**
 * Pure-string transformation: take a CSS value and a per-color
 * mapper, return the value with every color token replaced by the
 * mapper's output. Non-color substrings round-trip identically.
 */
export function rewriteColorsInValue(
  value: string,
  map: (rgb: Rgb) => Rgb,
): string {
  const tokens = findColorTokens(value)
  if (tokens.length === 0) return value
  let out = ''
  let cursor = 0
  for (const tok of tokens) {
    out += value.slice(cursor, tok.start)
    out += serializeColor(map(tok.rgb), tok.alpha, tok.format)
    cursor = tok.end
  }
  out += value.slice(cursor)
  return out
}
