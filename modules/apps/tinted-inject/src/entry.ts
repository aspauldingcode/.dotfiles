/**
 * Dendritic inject: TintedBrowse LUT rewriter for Vesktop / Spotify.
 *
 * Same pipeline as ~/TintedBrowse (OKLab Gaussian RBF default, lumFactor
 * 0.5, shape 128, preserveLuminance false). Does not remap CSS variables
 * to palette roles — walks authored colors and emits an override sheet.
 *
 * Palette sources (first hit wins, then polled):
 *   1. CSS vars --tb-base00 .. --tb-base0F (Vencord QuickCSS)
 *   2. ./tinted-palette.json next to the SPA (Spotify xpui clone)
 *   3. window.__DENDRITIC_PALETTE__
 */
import { LutRewriter } from './lut-rewriter'
import {
  buildColorMapper,
  DEFAULT_RECOLOR,
  paletteColorsForLut,
} from './lut'

const SLOTS = [
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

const PALETTE_STYLE_ID = 'tinted-browse-palette'

type PaletteMap = Record<(typeof SLOTS)[number], string>

let rewriter: LutRewriter | null = null
let lastFp = ''

function normalizeHex(raw: string): string | null {
  const t = raw.trim()
  if (!t) return null
  const h = t.startsWith('#') ? t : `#${t}`
  if (!/^#[0-9a-fA-F]{6}$/.test(h)) return null
  return h.toLowerCase()
}

function paletteFromCss(): PaletteMap | null {
  const cs = getComputedStyle(document.documentElement)
  const out = {} as PaletteMap
  for (const slot of SLOTS) {
    const v =
      normalizeHex(cs.getPropertyValue(`--tb-${slot}`)) ??
      normalizeHex(cs.getPropertyValue(`--${slot}`))
    if (!v) return null
    out[slot] = v
  }
  return out
}

function paletteFromWindow(): PaletteMap | null {
  const w = globalThis as { __DENDRITIC_PALETTE__?: Record<string, string> }
  const src = w.__DENDRITIC_PALETTE__
  if (!src) return null
  const out = {} as PaletteMap
  for (const slot of SLOTS) {
    const v = normalizeHex(src[slot] ?? '')
    if (!v) return null
    out[slot] = v
  }
  return out
}

function installPaletteStyle(p: PaletteMap): void {
  let el = document.getElementById(PALETTE_STYLE_ID) as HTMLStyleElement | null
  if (!el) {
    el = document.createElement('style')
    el.id = PALETTE_STYLE_ID
    el.setAttribute('data-tinted-browse', 'palette')
    const root = document.head ?? document.documentElement
    root.insertBefore(el, root.firstChild)
  }
  const decls = SLOTS.map((s) => `--tb-${s}: ${p[s]};`).join(' ')
  const css = `:root, :host { ${decls} }`
  if (el.textContent !== css) el.textContent = css
}

async function paletteFromJson(): Promise<PaletteMap | null> {
  const candidates = [
    new URL('tinted-palette.json', location.href).href,
    `${location.origin}/tinted-palette.json`,
  ]
  for (const url of candidates) {
    try {
      const resp = await fetch(`${url}?t=${Date.now()}`, { cache: 'no-store' })
      if (!resp.ok) continue
      const data = (await resp.json()) as Record<string, string>
      const out = {} as PaletteMap
      let ok = true
      for (const slot of SLOTS) {
        const v = normalizeHex(data[slot] ?? '')
        if (!v) {
          ok = false
          break
        }
        out[slot] = v
      }
      if (ok) return out
    } catch {
      /* try next */
    }
  }
  return null
}

function fingerprint(p: PaletteMap): string {
  return SLOTS.map((s) => p[s]).join(',')
}

function applyPalette(p: PaletteMap): void {
  const fp = fingerprint(p)
  if (fp === lastFp && rewriter) return
  lastFp = fp
  installPaletteStyle(p)
  rewriter?.clear()
  const mapColor = buildColorMapper(paletteColorsForLut(p), DEFAULT_RECOLOR)
  rewriter = new LutRewriter({
    doc: document,
    mapColor,
    fetchCrossOriginText: async (url) => {
      try {
        const resp = await fetch(url, { credentials: 'omit' })
        if (!resp.ok) return null
        return await resp.text()
      } catch {
        return null
      }
    },
  })
  rewriter.apply()
}

async function tick(): Promise<void> {
  const p =
    paletteFromCss() ?? paletteFromWindow() ?? (await paletteFromJson())
  if (p) applyPalette(p)
}

function boot(): void {
  void tick()
  setInterval(() => void tick(), 1500)
  document.addEventListener('visibilitychange', () => {
    if (document.visibilityState === 'visible') void tick()
  })
}

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', boot)
} else {
  boot()
}
