/**
 * Dendritic inject: TintedBrowse LUT rewriter for Vesktop / Spotify.
 *
 * Same pipeline as ~/TintedBrowse (OKLab Gaussian RBF default, lumFactor
 * 0.5, shape 128, preserveLuminance false). Does not remap CSS variables
 * to palette roles — walks authored CSS colors and emits an override sheet.
 *
 * Palette sources (first hit wins, then polled):
 *   1. CSS vars --tb-base00 .. --tb-base0F (Vencord QuickCSS / linked sheet)
 *   2. window.__DENDRITIC_PALETTE__ (extensions/tinted-palette.js)
 *   3. extensions/tinted-palette.json then ./tinted-palette.json
 *
 * Spotify's CEF origin is https://xpui.app.spotify.com/. Extra files
 * at the xpui root 404; Spicetify's interceptor serves extensions/*.
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
const PALETTE_LINK_ID = 'tinted-browse-palette-link'
const LUT_STYLE_ID = 'tinted-browse-lut-overrides'

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

function variantFromBase00(hex: string): 'light' | 'dark' {
  const h = hex.slice(1)
  const r = parseInt(h.slice(0, 2), 16)
  const g = parseInt(h.slice(2, 4), 16)
  const b = parseInt(h.slice(4, 6), 16)
  const y = (0.2126 * r + 0.7152 * g + 0.0722 * b) / 255
  return y > 0.5 ? 'light' : 'dark'
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

function parsePaletteRecord(data: Record<string, string>): PaletteMap | null {
  const out = {} as PaletteMap
  for (const slot of SLOTS) {
    const v = normalizeHex(data[slot] ?? '')
    if (!v) return null
    out[slot] = v
  }
  return out
}

const PALETTE_FILE_CANDIDATES = [
  'extensions/tinted-palette',
  '/extensions/tinted-palette',
  'tinted-palette',
  '/tinted-palette',
] as const

function paletteUrls(ext: 'css' | 'json' | 'js'): string[] {
  const out: string[] = []
  for (const base of PALETTE_FILE_CANDIDATES) {
    out.push(`${base}.${ext}`)
  }
  try {
    out.push(new URL(`extensions/tinted-palette.${ext}`, location.href).href)
    out.push(`${location.origin}/extensions/tinted-palette.${ext}`)
  } catch {
    /* no Location in some test docs */
  }
  return out
}

function ensurePaletteLink(): void {
  if (document.getElementById(PALETTE_LINK_ID)) return
  // Prefer the static Spicetify-style link appearance injects into
  // index.html. Only add a fallback if it is missing.
  if (document.querySelector('link[href*="tinted-palette.css"]')) return
  const link = document.createElement('link')
  link.id = PALETTE_LINK_ID
  link.rel = 'stylesheet'
  link.href = 'tinted-palette.css'
  const head = document.head ?? document.documentElement
  head.insertBefore(link, head.firstChild)
}

function ensurePaletteScript(): void {
  if (document.getElementById('tinted-browse-palette-script')) return
  const s = document.createElement('script')
  s.id = 'tinted-browse-palette-script'
  s.src = 'extensions/tinted-palette.js'
  s.onload = () => {
    void tick()
  }
  const head = document.head ?? document.documentElement
  head.appendChild(s)
}

function syncEncoreVariant(variant: 'light' | 'dark'): void {
  const want = variant === 'light' ? 'encore-light-theme' : 'encore-dark-theme'
  const drop = variant === 'light' ? 'encore-dark-theme' : 'encore-light-theme'
  const apply = (el: Element) => {
    el.classList.remove(drop)
    if (!el.classList.contains(want)) el.classList.add(want)
  }
  apply(document.documentElement)
  if (document.body) apply(document.body)
  document.querySelectorAll(`.${drop}`).forEach(apply)
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
  const variant = variantFromBase00(p.base00)
  document.documentElement.dataset.tintedBrowse = variant
  syncEncoreVariant(variant)
  const decls = SLOTS.map((s) => `--tb-${s}: ${p[s]};`).join(' ')
  const css = `:root, :host { color-scheme: ${variant}; ${decls} }`
  if (el.textContent !== css) el.textContent = css
}

function parsePaletteFromJs(text: string): PaletteMap | null {
  const markStart = text.indexOf('/*dendritic-palette*/')
  const markEnd = text.indexOf('/*dendritic-palette-end*/')
  const slice =
    markStart >= 0 && markEnd > markStart
      ? text.slice(markStart, markEnd)
      : text
  const start = slice.indexOf('{')
  const end = slice.lastIndexOf('}')
  if (start < 0 || end <= start) return null
  try {
    const data = JSON.parse(slice.slice(start, end + 1)) as Record<string, string>
    return parsePaletteRecord(data)
  } catch {
    return null
  }
}

async function fetchText(url: string): Promise<string | null> {
  try {
    const resp = await fetch(`${url}?t=${Date.now()}`, { cache: 'no-store' })
    if (!resp.ok) return null
    return await resp.text()
  } catch {
    return null
  }
}

async function paletteFromJson(): Promise<PaletteMap | null> {
  for (const url of paletteUrls('json')) {
    const text = await fetchText(url)
    if (!text) continue
    try {
      const parsed = parsePaletteRecord(JSON.parse(text) as Record<string, string>)
      if (parsed) return parsed
    } catch {
      /* try next */
    }
  }
  for (const url of [
    ...paletteUrls('js'),
    'extensions/dendritic-tint.js',
    '/extensions/dendritic-tint.js',
  ]) {
    const text = await fetchText(url)
    if (!text) continue
    const parsed = parsePaletteFromJs(text)
    if (parsed) return parsed
  }
  return null
}

function fingerprint(p: PaletteMap): string {
  return SLOTS.map((s) => p[s]).join(',')
}

function applyPalette(p: PaletteMap): void {
  const fp = fingerprint(p)
  const sheetGone = !document.getElementById(LUT_STYLE_ID)
  if (fp === lastFp && rewriter && !sheetGone) return
  lastFp = fp
  try {
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
    document.documentElement.dataset.tintedBrowseLut = 'on'
  } catch (err) {
    document.documentElement.dataset.tintedBrowseLut = 'error'
    console.error('[dendritic-tint] LUT apply failed', err)
    lastFp = ''
  }
}

async function tick(): Promise<void> {
  ensurePaletteLink()
  ensurePaletteScript()
  const p =
    paletteFromCss() ?? paletteFromWindow() ?? (await paletteFromJson())
  if (p) {
    syncEncoreVariant(variantFromBase00(p.base00))
    applyPalette(p)
  }
}

function boot(): void {
  ensurePaletteLink()
  ensurePaletteScript()
  void tick()
  window.addEventListener('load', () => void tick())
  setTimeout(() => void tick(), 500)
  setTimeout(() => void tick(), 2000)
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
