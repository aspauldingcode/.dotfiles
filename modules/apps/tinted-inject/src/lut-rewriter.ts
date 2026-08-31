import { rewriteColorsInValue } from './color-parser'
import type { ColorMapper } from './lut/options'

/**
 * The rewriter intentionally does NOT maintain a list of "color
 * properties". An earlier version did — and that's exactly why
 * sites like Stack Overflow, BBC and Amazon left huge swaths of UI
 * un-tinted: their stylesheets pile colors into long-tail properties
 * (`mask-image: linear-gradient(...)` for icon glyphs, `border-image`
 * for stylised borders, `--scrollbar-thumb-color` and a hundred other
 * design-token CSS variables, `filter: drop-shadow(...)`,
 * `text-decoration-color`, `caret-color`, `accent-color`, ...). Any
 * fixed allow-list lags real-world CSS authoring.
 *
 * Instead we walk *every* declaration on a rule and run a fast
 * regex probe (`hasColorToken`) over the value. Layout-only values
 * like `200px solid` / `auto` / `cover 0 0 / 100%` short-circuit in
 * the probe in nanoseconds, while any declaration whose value
 * contains a hex / rgb / named-color token gets handed off to the
 * full color-aware rewriter. This widens coverage across every site
 * without making the common case slower.
 */

/**
 * The DOM is laden with structural elements we never want to touch.
 * `<head>` children carry no visible style. `<script>` and `<style>`
 * have inline content that isn't visual. Anything inside an element
 * that ALREADY has our marker means we already rewrote it. Avoid
 * recursion into media-bearing elements — see also the parity
 * matrix's "media is preserved" guarantee.
 */
const SKIP_INLINE_STYLE_TAGS = new Set([
  'HEAD',
  'SCRIPT',
  'STYLE',
  'LINK',
  'META',
  'TITLE',
  'NOSCRIPT',
  'TEMPLATE',
  // Media: their `style` attributes can absolutely have colors (e.g.
  // a poster bg-color on `<video>`), but tinting media is the one
  // thing the user explicitly forbade. Skip them entirely.
  'IMG',
  'PICTURE',
  'SOURCE',
  'VIDEO',
  'AUDIO',
  'CANVAS',
  'IFRAME',
  'EMBED',
  'OBJECT',
])

const STYLE_ID = 'tinted-browse-lut-overrides'
const ORIGINAL_STYLE_DATA_ATTR = 'data-tinted-browse-original-style'

export interface LutRewriterOptions {
  /** Color mapper from `buildThemeLut` — required. */
  mapColor: ColorMapper
  /**
   * The document to operate on. Defaults to `document`, but the test
   * suite swaps in jsdom-built documents.
   */
  doc?: Document
  /**
   * Cross-origin stylesheet text loader. Real callers wire this to
   * `browser.runtime.sendMessage({ type: 'fetchStylesheet', url })`,
   * which the background service worker proxies via `fetch()` with
   * the extension's `<all_urls>` host permissions (so it isn't
   * subject to CORS the way the page realm is). Tests inject a
   * deterministic mock.
   *
   * If omitted, the rewriter degrades to "same-origin only" — which
   * is a meaningful coverage regression on real sites, since most
   * production CSS comes from CDNs.
   */
  fetchCrossOriginText?: (url: string) => Promise<string | null>
}

/**
 * The runtime engine that turns the active theme into a recolored
 * page. Two passes:
 *
 *   1. `rewriteAllStylesheets` — walks every reachable stylesheet
 *      (light DOM + adoptedStyleSheets + same-origin linked),
 *      rebuilds it with each color value run through the LUT, and
 *      injects the rebuilt rules as a single override stylesheet
 *      placed last in `<head>` so they win the cascade at equal
 *      specificity.
 *
 *   2. `rewriteAllInlineStyles` — walks every element with a `style`
 *      attribute and applies the same `rewriteColorsInValue` pass.
 *      The element's pre-rewrite style is preserved on the
 *      `data-tinted-browse-original-style` attribute so `clear()`
 *      can restore it without losing site authoring.
 *
 * Both passes are then kept in sync via mutation observers.
 */
export class LutRewriter {
  private readonly doc: Document
  private readonly mapColor: ColorMapper
  private readonly fetchCrossOriginText: ((url: string) => Promise<string | null>) | null
  private overrideStyle: HTMLStyleElement | null = null
  private styleObserver: MutationObserver | null = null
  private inlineObserver: MutationObserver | null = null
  private active = false
  // Same-origin pass output (sync, runs on every apply). Combined
  // with `crossOriginCss` to form the final override sheet content.
  private sameOriginCss = ''
  // Cross-origin pass output (async, populated by background-fetched
  // sheets). Held in a separate slot so the sync re-run on observer
  // events doesn't wipe it out — that would have been a major source
  // of un-tinted CDN-served CSS on busy SPAs.
  private crossOriginCss = ''
  // URL → fetched text (or null if the fetch failed and we want to
  // remember "don't retry"). Avoids re-fetching the same CDN sheet
  // every time the site appends an unrelated <style>.
  private readonly crossOriginCache = new Map<string, string | null>()
  // Bumps on every cross-origin run; an in-flight run that finishes
  // after a newer run started just discards its result.
  private crossOriginGen = 0
  // Cached originals for inline `style` attributes. We deliberately
  // store these in a WeakMap rather than a DOM data-attribute so the
  // observer feedback loop (writes to `style` fire the observer, which
  // would then read back the rewritten attribute) cannot accidentally
  // clobber the cached value. The DOM data-attribute is still set
  // alongside as documentation/inspectable hint, but the WeakMap is
  // the source of truth.
  private readonly inlineOriginals = new WeakMap<Element, string>()
  // Each element's most recent rewritten value (i.e. what we last
  // wrote into its `style` attribute). The inline observer compares
  // the current attribute against this; if they match, the mutation
  // is just our own write echoing back. This is more robust than
  // re-running the rewriter and string-matching, because the
  // serialization may go through browser normalization that we don't
  // control (e.g. some engines normalize `style` to a canonical form
  // on read).
  private readonly inlineLastWritten = new WeakMap<Element, string>()

  constructor(options: LutRewriterOptions) {
    this.doc = options.doc ?? document
    this.mapColor = options.mapColor
    this.fetchCrossOriginText = options.fetchCrossOriginText ?? null
  }

  /**
   * Apply the LUT to every stylesheet + inline style currently in
   * the document, and start observing for new ones. Idempotent — a
   * second call on the same instance just refreshes everything.
   *
   * The same-origin pass runs synchronously so there's no flash of
   * un-tinted content on first paint. The cross-origin pass is
   * kicked off asynchronously and appended to the override sheet
   * once it resolves; this is the only way to get tinting on real
   * sites that load most of their CSS from CDNs (Stack Overflow,
   * Amazon, BBC, etc.).
   */
  apply(): void {
    this.active = true
    this.rewriteAllStylesheets()
    this.rewriteAllInlineStyles(this.doc.documentElement)
    this.startObservers()
    void this.fetchAndApplyCrossOrigin()
  }

  /**
   * Undo the apply: restore every inline `style` to its original
   * value, remove the override stylesheet, stop the observers. Safe
   * to call when not active.
   */
  clear(): void {
    this.active = false
    this.stopObservers()
    if (this.overrideStyle?.parentNode) {
      this.overrideStyle.parentNode.removeChild(this.overrideStyle)
    }
    this.overrideStyle = null
    this.sameOriginCss = ''
    this.crossOriginCss = ''
    this.crossOriginGen += 1 // discard any in-flight async result
    this.restoreAllInlineStyles(this.doc.documentElement)
  }

  // ───────────────────────────────────────────────────────── stylesheets

  private rewriteAllStylesheets(): void {
    const ownSheet = this.overrideStyle?.sheet ?? null
    const out: string[] = []
    for (const sheet of Array.from(this.doc.styleSheets)) {
      // Skip our own override sheet to avoid an infinite re-rewrite
      // loop. We compare by reference (and by ownerNode duck-type as
      // a fallback) because some environments — notably jsdom — do
      // not populate `sheet.ownerNode`.
      if (sheet === ownSheet) continue
      if (this.isOurOverrideSheet(sheet)) continue
      try {
        const text = serializeStylesheet(sheet, this.mapColor)
        if (text) out.push(text)
      } catch {
        // Cross-origin stylesheets throw on `cssRules` access. The
        // sync pass just skips them — the cross-origin pass below
        // re-fetches them via the background script (which has
        // `host_permissions` for `<all_urls>` and isn't subject to
        // CORS) and appends them to the override sheet.
      }
    }
    if (this.doc.adoptedStyleSheets && this.doc.adoptedStyleSheets.length > 0) {
      // CSSStyleSheet API: same approach as above.
      for (const sheet of this.doc.adoptedStyleSheets) {
        try {
          const text = serializeConstructableSheet(sheet, this.mapColor)
          if (text) out.push(text)
        } catch {
          /* noop */
        }
      }
    }

    this.sameOriginCss = out.join('\n')
    this.installOverrideSheet()
  }

  private installOverrideSheet(): void {
    if (!this.overrideStyle) {
      const el = this.doc.createElement('style')
      el.id = STYLE_ID
      el.setAttribute('data-tinted-browse', 'lut-overrides')
      this.overrideStyle = el
    }
    const css = this.crossOriginCss
      ? `${this.sameOriginCss}\n${this.crossOriginCss}`
      : this.sameOriginCss
    if (this.overrideStyle.textContent !== css) {
      this.overrideStyle.textContent = css
    }
    // Always re-append so we end up last in `<head>`. If the site
    // adds new <style>/<link> nodes we re-run apply(); each call
    // moves us back to the bottom of the cascade.
    const head = this.doc.head ?? this.doc.documentElement
    if (this.overrideStyle.parentNode !== head) {
      head.appendChild(this.overrideStyle)
    } else if (head.lastElementChild !== this.overrideStyle) {
      head.appendChild(this.overrideStyle) // moves it
    }
  }

  private isOurOverrideSheet(sheet: CSSStyleSheet): boolean {
    // Duck-type rather than `instanceof Element` so this works across
    // realms (e.g. content script vs page realm). Any node whose
    // `id` matches our reserved STYLE_ID is one of ours.
    const owner = sheet.ownerNode as { id?: string } | null
    return owner?.id === STYLE_ID
  }

  // ───────────────────────────────────────────────────────── cross-origin

  /**
   * Walk every same-document stylesheet whose `cssRules` access
   * threw (i.e. is cross-origin), pull its text via the background
   * fetcher (a `runtime.sendMessage` round-trip the caller provides),
   * parse it into a Constructable Stylesheet, and feed the result
   * into the same serializer that the sync pass uses. The output is
   * appended to the override sheet.
   *
   * Each `apply()` bumps a generation counter so a slow async run
   * arriving after a newer apply / clear is silently discarded
   * instead of stomping the override sheet.
   */
  private async fetchAndApplyCrossOrigin(): Promise<void> {
    if (!this.active) return
    if (!this.fetchCrossOriginText) return

    const gen = ++this.crossOriginGen
    const urls: string[] = []
    for (const sheet of Array.from(this.doc.styleSheets)) {
      const ownSheet = this.overrideStyle?.sheet ?? null
      if (sheet === ownSheet) continue
      if (this.isOurOverrideSheet(sheet)) continue
      const href = sheet.href
      if (!href) continue
      try {
        // Probe — same-origin sheets succeed; cross-origin throws.
        // We touch `cssRules` rather than length to be robust to
        // engines that compute cssRules lazily.
        // eslint-disable-next-line @typescript-eslint/no-unused-expressions
        sheet.cssRules
        continue // same-origin, already handled
      } catch {
        urls.push(href)
      }
    }
    if (urls.length === 0) return

    // Fan-out fetch. A cached "we already failed" entry is treated
    // as a permanent skip for this session so we don't hammer
    // unreachable CDNs.
    const fetchedTexts = await Promise.all(
      urls.map(async (url) => {
        if (this.crossOriginCache.has(url)) {
          return { url, text: this.crossOriginCache.get(url) ?? null }
        }
        const text = await this.fetchCrossOriginText!(url).catch(() => null)
        this.crossOriginCache.set(url, text)
        return { url, text }
      }),
    )

    if (gen !== this.crossOriginGen) return // stale
    if (!this.active) return

    const out: string[] = []
    for (const { url, text } of fetchedTexts) {
      if (!text) continue
      const sheet = parseTextAsStylesheet(text, this.doc)
      if (!sheet) continue
      try {
        const rewritten = serializeStylesheet(sheet, this.mapColor)
        if (rewritten) {
          // Annotate the chunk so DevTools tells you which CDN URL
          // contributed which override block. Cheap and zero impact
          // on cascade.
          out.push(`/* tinted-browse cross-origin: ${url} */\n${rewritten}`)
        }
      } catch {
        /* parse errors fall through */
      }
    }

    if (gen !== this.crossOriginGen) return
    if (!this.active) return

    this.crossOriginCss = out.join('\n')
    this.installOverrideSheet()
  }

  // ───────────────────────────────────────────────────────── inline styles

  private rewriteAllInlineStyles(root: ParentNode): void {
    // querySelectorAll('[style]') is fast even on huge DOMs because
    // browsers maintain an internal attribute index for it.
    const candidates = (root as Element | Document).querySelectorAll('[style]')
    candidates.forEach((el) => this.rewriteInlineStyle(el))
  }

  private rewriteInlineStyle(el: Element): void {
    if (SKIP_INLINE_STYLE_TAGS.has(el.tagName)) return
    const value = el.getAttribute('style')
    if (value === null) return

    // First time we've seen this element? The current attribute is
    // the original — cache it.
    let original = this.inlineOriginals.get(el)
    if (original === undefined) {
      if (!hasColorToken(value)) return
      original = value
      this.inlineOriginals.set(el, original)
      // Surface the original on a data-attribute purely for
      // inspectability — the WeakMap is canonical, but DevTools
      // users will appreciate seeing the pre-rewrite value.
      el.setAttribute(ORIGINAL_STYLE_DATA_ATTR, original)
    }

    const rewritten = rewriteColorsInValue(original, this.mapColor)
    if (rewritten !== value) {
      this.inlineLastWritten.set(el, rewritten)
      el.setAttribute('style', rewritten)
    } else {
      // Even when no write is needed (e.g. on re-apply with the same
      // theme), record the value as our latest "expected" so the
      // observer doesn't mistake a future no-op rewrite as
      // site-driven churn.
      this.inlineLastWritten.set(el, value)
    }
  }

  private restoreAllInlineStyles(root: ParentNode): void {
    const els = (root as Element | Document).querySelectorAll(
      `[${ORIGINAL_STYLE_DATA_ATTR}]`,
    )
    els.forEach((el) => {
      // Restore from the WeakMap (canonical) rather than the
      // data-attribute (might be stale after observer churn).
      const original = this.inlineOriginals.get(el)
      if (original !== undefined) {
        el.setAttribute('style', original)
      }
      this.inlineOriginals.delete(el)
      el.removeAttribute(ORIGINAL_STYLE_DATA_ATTR)
    })
  }

  // ───────────────────────────────────────────────────────── observers

  private startObservers(): void {
    if (typeof MutationObserver === 'undefined') return
    if (this.styleObserver || this.inlineObserver) return

    let scheduled = false
    const refresh = () => {
      scheduled = false
      if (!this.active) return
      this.rewriteAllStylesheets()
      // New <link> elements may point to cross-origin CDNs we haven't
      // seen before; let the async path catch them up.
      void this.fetchAndApplyCrossOrigin()
    }

    // Sheet observer: fires on <style>/<link> additions/removals
    // anywhere in the document. Throttled to one frame.
    this.styleObserver = new MutationObserver((records) => {
      if (!this.active) return
      let needSheets = false
      const newElements: Element[] = []
      for (const r of records) {
        if (r.type === 'childList') {
          for (const n of r.addedNodes) {
            if (n instanceof Element) {
              if (n.tagName === 'STYLE' || n.tagName === 'LINK') {
                needSheets = true
              }
              if (n.querySelector?.('style, link')) needSheets = true
              newElements.push(n)
            }
          }
        }
      }
      if (needSheets && !scheduled) {
        scheduled = true
        requestAnimationFrameSafe(refresh)
      }
      // Inline-style sweep on each newly-added subtree.
      for (const el of newElements) {
        if (el.hasAttribute?.('style')) this.rewriteInlineStyle(el)
        // also descendants
        if ('querySelectorAll' in el) {
          this.rewriteAllInlineStyles(el)
        }
      }
    })
    this.styleObserver.observe(this.doc.documentElement, {
      childList: true,
      subtree: true,
    })

    // Inline-style observer: fires when any element's `style`
    // attribute changes (CSS-in-JS frameworks do this constantly on
    // hover / focus / animation).
    //
    // Echo-detection: `inlineLastWritten[el]` holds the value we
    // most recently wrote to `el.style`. If a mutation arrives with
    // `current === inlineLastWritten[el]`, this is just our own
    // setAttribute() echoing back — skip. Anything else is the site
    // genuinely changing the inline style; in that case we drop the
    // cached original so the next rewrite re-snapshots.
    this.inlineObserver = new MutationObserver((records) => {
      if (!this.active) return
      for (const r of records) {
        if (
          r.type !== 'attributes' ||
          r.attributeName !== 'style' ||
          !(r.target instanceof Element)
        ) {
          continue
        }
        const el = r.target
        const current = el.getAttribute('style') ?? ''
        const lastWritten = this.inlineLastWritten.get(el)
        if (lastWritten !== undefined && current === lastWritten) {
          continue // our own write
        }
        // Site changed the inline style — re-snapshot the original
        // and rewrite. This handles CSS-in-JS frameworks that
        // mutate `style` on hover / focus / animation.
        this.inlineOriginals.delete(el)
        el.removeAttribute(ORIGINAL_STYLE_DATA_ATTR)
        this.rewriteInlineStyle(el)
      }
    })
    this.inlineObserver.observe(this.doc.documentElement, {
      subtree: true,
      attributes: true,
      attributeFilter: ['style'],
    })
  }

  private stopObservers(): void {
    this.styleObserver?.disconnect()
    this.styleObserver = null
    this.inlineObserver?.disconnect()
    this.inlineObserver = null
  }
}

// ──────────────────────────────────────────────────────────── utilities

const COLOR_TOKEN_FAST_PROBE = /(#[0-9a-fA-F]{3,8}\b|\brgba?\(|\bhsla?\(|\b(?:red|blue|green|black|white|yellow|cyan|magenta|orange|pink|gray|grey|purple)\b)/i

/**
 * Cheap "could this string contain a color?" probe so we can skip
 * the heavy regex / parser pipeline when an inline style is purely
 * layout-related (e.g. `width:200px;height:100px`). Keeps the
 * inline observer fast on high-fan-out DOMs.
 */
function hasColorToken(value: string): boolean {
  return COLOR_TOKEN_FAST_PROBE.test(value)
}

function requestAnimationFrameSafe(fn: () => void): void {
  if (typeof requestAnimationFrame === 'function') {
    requestAnimationFrame(fn)
  } else {
    queueMicrotask(fn)
  }
}

/**
 * Walk a CSSStyleSheet's rules and emit a string of overriding rules
 * — one per rule found — with every color value re-mapped through
 * the LUT. Empty result if nothing in the sheet had a color.
 */
function serializeStylesheet(
  sheet: CSSStyleSheet,
  mapColor: ColorMapper,
): string {
  const rules = sheet.cssRules
  if (!rules) return ''
  const out: string[] = []
  // Bracket indexing is portable across the spec'd CSSRuleList
  // surface and jsdom's implementation, which doesn't ship `.item()`.
  for (let i = 0; i < rules.length; i += 1) {
    const r = rules[i]
    if (!r) continue
    serializeRule(r, mapColor, out)
  }
  return out.join('\n')
}

function serializeConstructableSheet(
  sheet: CSSStyleSheet,
  mapColor: ColorMapper,
): string {
  return serializeStylesheet(sheet, mapColor)
}

/**
 * Recursively walk a single CSSRule. For style rules, emit a
 * declaration block with only the color-bearing properties (and only
 * those whose mapped value differs from the authored one). For
 * grouping rules (@media, @supports), recurse into them and re-wrap
 * the result.
 *
 * NB: we duck-type instead of using `instanceof CSSStyleRule` etc.
 * jsdom and the page realm define separate constructor classes; an
 * `instanceof` against the extension realm's `CSSStyleRule` returns
 * `false` for rules whose ownerDocument is the page. Duck-typing on
 * the structural shape (`selectorText` for style rules, `keyText`
 * for keyframe rules, `cssRules` for grouping rules) is realm-safe.
 */
type StyleRuleLike = { selectorText: string; style: CSSStyleDeclaration }
type KeyframeRuleLike = { keyText: string; style: CSSStyleDeclaration }
type KeyframesRuleLike = { name: string; cssRules: CSSRuleList }
type GroupingRuleLike = { cssRules: CSSRuleList }
type ImportRuleLike = { styleSheet: CSSStyleSheet; href: string }

function isStyleRule(rule: CSSRule): rule is CSSRule & StyleRuleLike {
  return (
    typeof (rule as Partial<StyleRuleLike>).selectorText === 'string' &&
    'style' in rule
  )
}
function isKeyframeRule(rule: CSSRule): rule is CSSRule & KeyframeRuleLike {
  return (
    typeof (rule as Partial<KeyframeRuleLike>).keyText === 'string' &&
    'style' in rule
  )
}
function isKeyframesRule(rule: CSSRule): rule is CSSRule & KeyframesRuleLike {
  return (
    'name' in rule &&
    'cssRules' in rule &&
    !('selectorText' in rule) &&
    !('keyText' in rule)
  )
}
function isImportRule(rule: CSSRule): rule is CSSRule & ImportRuleLike {
  return (
    'styleSheet' in rule &&
    typeof (rule as Partial<ImportRuleLike>).href === 'string'
  )
}
function isGroupingRule(rule: CSSRule): rule is CSSRule & GroupingRuleLike {
  // Style rules and keyframes rules have `cssRules` too in some
  // engines, so check those first.
  return (
    'cssRules' in rule &&
    !isStyleRule(rule) &&
    !isKeyframesRule(rule) &&
    !isImportRule(rule)
  )
}

function serializeRule(
  rule: CSSRule,
  mapColor: ColorMapper,
  out: string[],
): void {
  if (isStyleRule(rule)) {
    const decls = collectColorDecls(rule.style, mapColor)
    if (decls.length === 0) return
    out.push(`${rule.selectorText} { ${decls.join('; ')} }`)
    return
  }

  if (isKeyframesRule(rule)) {
    const inner: string[] = []
    for (let i = 0; i < rule.cssRules.length; i += 1) {
      const k = rule.cssRules[i]
      if (!k || !isKeyframeRule(k)) continue
      const decls = collectColorDecls(k.style, mapColor)
      if (decls.length === 0) continue
      inner.push(`${k.keyText} { ${decls.join('; ')} }`)
    }
    if (inner.length === 0) return
    out.push(`@keyframes ${rule.name} { ${inner.join('\n')} }`)
    return
  }

  if (isImportRule(rule)) {
    // A CSS `@import` makes the importing sheet logically include the
    // imported sheet's rules in order. Real browsers walk into the
    // imported sheet for cascade and we have to match that or we miss
    // every color in any same-origin "main.css → imports
    // tokens.css → imports buttons.css" chain. Cross-origin
    // @imports throw on .cssRules access — we let the catch in the
    // top-level walker handle that, same as a top-level cross-origin
    // <link>.
    try {
      const text = serializeStylesheet(rule.styleSheet, mapColor)
      if (text) out.push(text)
    } catch {
      /* cross-origin @import — caught upstream */
    }
    return
  }

  if (isGroupingRule(rule)) {
    const inner: string[] = []
    for (let i = 0; i < rule.cssRules.length; i += 1) {
      const child = rule.cssRules[i]
      if (child) serializeRule(child, mapColor, inner)
    }
    if (inner.length === 0) return
    out.push(`${atRuleHeader(rule)} { ${inner.join('\n')} }`)
  }
  // Other rule kinds (@font-face, @page, @namespace) carry no
  // theme-relevant colors.
}

/**
 * Parse arbitrary CSS text into a CSSStyleSheet object the rewriter
 * can walk. Used by the cross-origin path: the background script
 * fetches the raw CSS bytes, then the content script feeds them
 * through this so the same `serializeStylesheet` machinery (used for
 * inline `<style>` and same-origin `<link>`) can extract color
 * declarations.
 *
 * Prefers the modern Constructable Stylesheet API (Chrome 73+,
 * Firefox 101+, Safari 16.4+ — fully covered by our minimum browser
 * targets) and falls back to a transient `<style>` element for older
 * runtimes.
 */
function parseTextAsStylesheet(text: string, doc: Document): CSSStyleSheet | null {
  const Ctor = (globalThis as { CSSStyleSheet?: typeof CSSStyleSheet }).CSSStyleSheet
  if (
    typeof Ctor === 'function' &&
    typeof Ctor.prototype.replaceSync === 'function'
  ) {
    try {
      const sheet = new Ctor()
      sheet.replaceSync(text)
      return sheet
    } catch {
      /* fall through to <style> fallback */
    }
  }
  // Fallback for environments without Constructable Stylesheets:
  // append a hidden <style>, take its `.sheet`, then remove it from
  // the DOM. The CSSStyleSheet object remains live and walkable
  // after detach in every conformant engine.
  try {
    const el = doc.createElement('style')
    el.textContent = text
    const head = doc.head ?? doc.documentElement
    head.appendChild(el)
    const sheet = el.sheet
    head.removeChild(el)
    return sheet ?? null
  } catch {
    return null
  }
}

function atRuleHeader(rule: CSSRule): string {
  // Pull the prefix (everything before the first `{`) out of cssText.
  // Works for @media, @supports, @container, @layer, etc. without
  // realm-specific instanceof checks.
  const text = rule.cssText
  const open = text.indexOf('{')
  return open > 0 ? text.slice(0, open).trim() : ''
}

function collectColorDecls(
  decl: CSSStyleDeclaration,
  mapColor: ColorMapper,
): string[] {
  const out: string[] = []
  for (let i = 0; i < decl.length; i += 1) {
    const name = decl.item(i)
    if (!name) continue
    const value = decl.getPropertyValue(name)
    // Fast probe first — cheap regex test that rejects layout-only
    // values (`12px solid`, `auto`, `inset 0 0 / 100%`) in a single
    // pass and lets the heavier `rewriteColorsInValue` handle only
    // the small fraction of declarations that actually mention a
    // color. This is what makes "rewrite EVERY property without an
    // allow-list" affordable on huge sites.
    if (!value || !hasColorToken(value)) continue
    const rewritten = rewriteColorsInValue(value, mapColor)
    if (rewritten === value) continue
    const priority = decl.getPropertyPriority(name)
    out.push(
      `${name}: ${rewritten}${priority ? ` !${priority}` : ''}`,
    )
  }
  return out
}
