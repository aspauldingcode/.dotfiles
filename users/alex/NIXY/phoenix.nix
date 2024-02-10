{ ... }:

# macOS Pheonix Window Manager Config
{

 # Note: to use phoenix typescript, learn of phoenix typings: https://github.com/mafredri/phoenix-typings/
 home.file.phoenix = {
   executable = true;
   target = ".config/phoenix/phoenix.js"; # javascript first.
   text = /*let inherit (config.colorScheme) colors; in*/ /* javascript */ ''
   Phoenix.notify("Phoenix config loading")
   Phoenix.set({
     daemon: false,
     openAtLogin: true
   })
   (() => {
     "use strict";

     function e(e, i) {
       return e.x >= i.x && e.x <= i.x + i.width && e.y >= i.y && e.y <= i.y + i.height
     }
     const i = new Map;

     function t(e, i, t) {
       if (Array.isArray(e)) {
         const o = e.map((e => n(e, i, t)));
         return () => o.forEach((e => e()))
       }
       return n(e, i, t)
     }

     function n(e, t, n) {
       const o = new Key(e, t, n),
       s = function (e, i) {
         return e + i.sort().join()
       }(e, t);
       return i.set(s, o), () => function (e) {
         const t = i.get(e);
         t && (t.disable(), i.delete(e))
       }(s)
     }
     const o = Object.assign((function (...e) {
       e = e.map((e => s(e))), Phoenix.log(...e), console.trace(...e)
     }), {
       notify: (...e) => {
         e = e.map((e => s(e))), Phoenix.log(...e);
         const i = e.join(" ");
         Phoenix.notify(i), console.trace(...e)
       },
       noTrace: (...e) => {
         e = e.map((e => s(e))), Phoenix.log(...e), console.log(...e)
       }
     });

     function s(e) {
       if (e instanceof Error) {
         let i = "";
         if (e.stack) {
           const t = e.stack.trim().split("\n");
           t[0] += ` (:${e.line}:${e.column})`, i = "\n" + t.map((e => "\t at " + e)).join("\n")
         }
         return `\n${e.toString()}${i}`
       }
       switch (typeof e) {
         case "object":
         return "\n" + JSON.stringify(e, null, 2);
         case "function":
         return e.toString();
         default:
         return e
       }
     }
     var r;

     function d(e, i, t = 1, n) {
       const s = new Modal;
       s.text = i, s.duration = t, n && (s.icon = n),
       function (e, i) {
         ! function (e, i, t, n) {
           const {
             height: s,
             width: r,
             x: d,
             y: a
           } = e.frame(), l = i.visibleFrame();
           e.origin = {
             x: l.x + (l.width / t - r / 2),
             y: l.y + (l.height / n - s / 2)
           }, o(e.origin), e.show()
         }(e, i, 2, 1 + 1 / 3)
       }(s, e)
     }! function (e) {
       e[e.NorthWest = 0] = "NorthWest", e[e.NorthEast = 1] = "NorthEast", e[e.SouthWest = 2] = "SouthWest", e[e.SouthEast = 3] = "SouthEast"
     }(r || (r = {}));
     const a = App.get("Phoenix") || App.get("Phoenix (Debug)");
     class l {
       constructor(e, i) {
         this.workspace = null, this.screen = e, this.id = i
       }
       setWorkspace(e) {
         var i, t;
         (null === (t = null === (i = this.workspace) || void 0 === i ? void 0 : i.screen) || void 0 === t ? void 0 : t.id) === this.id && (this.workspace.screen = null);
         let n = u[e];
         this.workspace = n, n.screen = this
       }
       activateWorkspace(e) {
         var i;
         this.setWorkspace(e);
         let t = u[e];
         t.render(), k(t.windows[0]), Phoenix.log(this.id + " " + (null === (i = this.workspace) || void 0 === i ? void 0 : i.id)), this.vlog("Activated")
       }
       vlog(e, i = !0) {
         var t;
         i && (e += " " + (null === (t = this.workspace) || void 0 === t ? void 0 : t.id)), d(this.screen, e, 1, a && a.icon())
       }
       hideAllApps() {
         let e = this.screen.frame();
         this.screen.windows({
           visible: !0
         }).forEach((i => {
           e.y = e.height, i.setTopLeft(e)
         }))
       }
     }
     class h {
       constructor(e) {
         this.windows = [], this.screen = null, this.mainRatio_ = .8, this.id = e
       }
       set mainRatio(e) {
         this.mainRatio_ = Math.max(Math.min(e, .95), 0)
       }
       get mainRatio() {
         return this.mainRatio_
       }
       garbageCollect() {
         let e = new Set(Window.all().map((e => e.hash())));
         this.windows = this.windows.filter((i => e.has(i.hash())))
       }
       render() {
         if (this.garbageCollect(), !this.screen) throw new Error("render called without a screen: " + this.id);
         if (0 == this.windows.length) return void this.screen.hideAllApps();
         let e = this.screen.screen.flippedVisibleFrame(),
         i = e.width * this.mainRatio_;
         for (let t = this.windows.length - 1; t >= 0; t--) {
           let n = this.windows[t],
           o = Object.assign({}, e);
           if (0 === t) this.windows.length > 1 && (o.width = i), n.setTopLeft(o), n.setSize(o);
           else {
             let s = this.windows.length - 1;
             o.x = e.x + i + 1, o.width = e.width - i, o.height = e.height / s, o.y = e.y + e.height / s * (t - 1) + 1, n.frame().width < o.width && n.setTopLeft(o), n.setSize(o), n.setTopLeft(o)
           }
           n.focus()
         }! function () {
           var e;
           let i = {
             workspaces: [],
             screens: [],
             mouseMoveFocus: w,
             autoAddWindows: f
           };
           for (let t of g) i.screens.push({
             id: t.id,
             workspace: null === (e = t.workspace) || void 0 === e ? void 0 : e.id
           });
           for (let e of u) i.workspaces.push({
             id: e.id,
             mainRatio: e.mainRatio,
             windows: e.windows.map((e => e.hash()))
           });
           o("============SAVING============"), Storage.set("state", i)
         }()
       }
       spin() {
         let e = this.windows.shift();
         e && this.windows.push(e), o(this.windows.map((e => e.title()))), this.modal("Spinning "), this.render()
       }
       modal(e) {
         var i;
         this.screen && (null === (i = this.screen) || void 0 === i || i.vlog(e))
       }
       findIndexByHash(e) {
         return this.windows.findIndex((i => e === i.hash()))
       }
       findIndex(e) {
         return this.findIndexByHash(e.hash())
       }
       removeWindow(e) {
         let i = this.findIndex(e); - 1 != i && (this.windows.splice(i, 1), this.screen && this.render())
       }
       addWindow(e, i) {
         if (-1 != this.findIndex(e)) return void this.modal("Window already on ");
         let t = c.get(e.hash());
         t && t.removeWindow(e), i ? this.windows.unshift(e) : this.windows.push(e), c.set(e.hash(), this), this.screen && this.render(), this.modal("Adding window to ")
       }
     }
     let c = new Map,
     w = !1,
     f = !0;
     o(Window.all().map((e => e.hash() + " " + e.title())));
     let u = [];
     for (let e = 0; e <= 9; e++) u.push(new h(e));
     let p = Window.focused(),
     g = [];

     function v() {
       for (let e of u) e.screen = null;
       g = [];
       for (let [e, i] of Screen.all().entries()) g.push(new l(i, e));
       ! function () {
         let e = Window.all(),
         i = Storage.get("state");
         if (o("============LOADING============"), o(i), i) {
           for (let t of i.workspaces || []) {
             o("Workspace " + t.id);
             let i = u[t.id];
             t.mainRatio && (i.mainRatio = t.mainRatio);
             for (let n of t.windows) {
               let t = e.find((e => e.hash() === n));
               t && i.addWindow(t)
             }
           }
           for (let e of i.screens || []) e.workspace && e.id < g.length && g[e.id].activateWorkspace(e.workspace);
           w = !!i.mouseMoveFocus, f = !!i.autoAddWindows
         }
       }(), g.sort(((e, i) => e.screen.frame().x - i.screen.frame().x));
       for (let [e, i] of g.entries()) i.workspace || i.activateWorkspace(e + 1);
       k(p)
     }

     function m() {
       let i = Mouse.location();
       return g.find((t => {
         let n = t.screen.flippedFrame();
         return e(i, n)
       })) || g[0]
     }

     function W(e) {
       let i = Window.focused();
       i && (u[e].addWindow(i, !0), y().render())
     }

     function k(e) {
       if (!e) return;
       e.focus();
       let i = e.frame();
       o("Focusing: " + e.title()), Mouse.move(A(i))
     }

     function x(e, i) {
       return (e + i) / 2
     }

     function A(e) {
       return {
         x: x(e.x, e.x + e.width),
         y: x(e.y, e.y + e.height)
       }
     }

     function y() {
       var e;
       let i = m();
       return o("getActiveWorkspace: screen: " + i.id + " workspace: " + (null === (e = i.workspace) || void 0 === e ? void 0 : e.id)), i.workspace
     }
     v();
     const S = ["alt"],
     E = [...S, "shift"];

     function M(e = 1) {
       let i = g.findIndex((e => e === m()));
       return g[Math.max(0, Math.min(g.length - 1, i + e))]
     }

     function P(e = 1) {
       var i;
       let t = M(e);
       (null === (i = t.workspace) || void 0 === i ? void 0 : i.windows.length) ? k(t.workspace.windows[0]): Mouse.move(A(t.screen.flippedFrame()))
     }
     Phoenix.set({
       daemon: !1,
       openAtLogin: !0
     }), t("right", S, (() => {
       P(1)
     })), t("right", E, (() => {
       let e = M().workspace;
       e && (W(e.id), k(e.windows[0]))
     })), t("left", S, (() => {
       P(-1)
     })), t("left", E, (() => {
       let e = M(-1).workspace;
       e && (W(e.id), k(e.windows[0]))
     })), t("down", S, (() => R())), t("j", S, (() => R())), t("up", S, (() => R(-1))), t("k", S, (() => R(-1))), t("h", S, (() => {
       y().mainRatio -= .1, y().render()
     })), t("h", E, (() => {
       y().mainRatio -= .01, y().render()
     })), t("l", S, (() => {
       y().mainRatio += .1, y().render()
     })), t("l", E, (() => {
       y().mainRatio += .01, y().render()
     })), t("return", S, (() => {
       let e = Window.focused();
       e && y().addWindow(e)
     })), t("return", E, (() => {
       let e = Window.focused();
       if (e)
       for (let i of e.app().windows()) c.has(i.hash()) || y().addWindow(i)
     })), t("delete", S, (() => {
       let e = Window.focused();
       e && y().removeWindow(e)
     })), t("c", E, (() => {
       let e = Window.focused();
       null == e || e.close()
     })), t("space", S, (() => {
       let e = Window.focused();
       if (!e) return;
       let i = u.find((i => e && -1 != i.findIndex(e)));
       i ? m().activateWorkspace(i.id) : m().vlog("No workspace for " + e.title(), !1)
     })), t("space", E, (() => {
       var e;
       let i = Window.focused();
       for (let i of g) null === (e = i.workspace) || void 0 === e || e.render(), i.vlog("Rerendered");
       k(i)
     })), t("r", S, (() => {
       y().spin()
     })), t("r", E, (() => {
       let e = Mouse.location(),
       i = g.map((e => e.workspace)),
       t = i.shift();
       i.push(t), o(i.map((e => e.id))), g.forEach(((e, t) => {
         o("setting SCREEN:" + e.id + " WINDOW: " + i[t].id), e.setWorkspace(i[t].id)
       })), g.forEach((e => {
         var i, t;
         o("rendering SCREEN:" + e.id + " WINDOW: " + (null === (i = e.workspace) || void 0 === i ? void 0 : i.id)), null === (t = e.workspace) || void 0 === t || t.render()
       })), Mouse.move(e)
     })), t("m", S, (() => {
       var e;
       w = e = !w, m().vlog("Mouse focus " + (e ? "enabled" : "disabled"), !1)
     })), t("a", S, (() => {
       var e;
       f = e = !f, m().vlog("Auto-add windows " + (e ? "enabled" : "disabled"), !1)
     }));
     for (let e = 0; e <= 9; e++) t(e.toString(), S, (() => {
       let i = u[e];
       if (i.screen) {
         let e = Window.focused(),
         t = m();
         return o(t.id), o(null == e ? void 0 : e.title()), i.screen !== t ? (i.screen.vlog("Here "), t.vlog("Already Showing " + i.id, !1)) : t.vlog("This is"), i.render(), void(t === i.screen ? (o(t.id), k(i.windows[0])) : (o(null == e ? void 0 : e.title()), k(e)))
       }
       m().activateWorkspace(e)
     })), t(e.toString(), E, (() => {
       W(e)
     }));

     function R(e = 1) {
       let i = Window.focused();
       if (!i) {
         let e = m();
         return void(e.workspace && e.activateWorkspace(e.workspace.id))
       }
       let t = i.hash(),
       n = c.get(t);
       if (!n) return;
       let o = n.windows;
       k(o[(n.findIndex(i) + e + o.length) % o.length])
     }
     Event.on("screensDidChange", (() => {
       v()
     })), Event.on("windowDidClose", (e => {
       let i = c.get(e.hash());
       i && (o("windowDidClose " + e.title() + " APPNAME: " + e.app().name() + " HASH: " + e.hash() + " removing from: " + i.id), i.removeWindow(e))
     })), Event.on("windowDidOpen", (e => {
       o("windowDidOpen " + e.title() + " APPNAME: " + e.app().name() + " HASH: " + e.hash() + " adding to: " + y().id), e.isVisible() && !c.get(e.hash()) && (o("windowDidOpen " + e.title() + " APPNAME: " + e.app().name() + " HASH: " + e.hash() + " adding to: " + y().id), "Phoenix" != e.app().name() && y().addWindow(e, !0))
     })), Event.on("appDidLaunch", (e => {
       o("appDidLaunch " + e.name() + " HASH: " + e.hash() + " adding to: " + y().id);
       for (let i of e.windows()) {
         if (!i.isVisible() || c.get(i.hash())) return;
         o("appDidLaunch " + i.title() + " APPNAME: " + i.app().name() + " HASH: " + i.hash() + " adding to: " + y().id), "Phoenix" != i.app().name() && y().addWindow(i, !0)
       }
     })), Event.on("appDidTerminate", (e => {
       for (let i of e.windows()) {
         let e = c.get(i.hash());
         if (!e) return;
         o("appDidTerminate " + i.title() + " APPNAME: " + i.app().name() + " HASH: " + i.hash() + " removing from: " + e.id), e.removeWindow(i)
       }
     })), Event.on("mouseDidMove", (i => {
       if (!w || i.modifiers.find((e => e === S[0]))) return;
       let t = Window.recent().find((t => e(i, t.frame())));
       null == t || t.focus()
     })), t("`", S, (() => {
       var e, i;
       for (let t of g)
       for (let n of (null === (e = t.workspace) || void 0 === e ? void 0 : e.windows) || []) {
         const e = new Modal;
         e.text = ((null === (i = t.workspace) || void 0 === i ? void 0 : i.id.toString()) || "") + " " + n.title(), e.duration = 3, e.icon = n.app().icon();
         let o = e.frame(),
         s = A(n.frame()),
         r = t.screen.flippedFrame(),
         d = s.y - r.y;
         d = r.height - d, s.x -= o.width / 2, s.y = d - o.height + t.screen.frame().y, e.origin = s, e.show()
       }
     })), t("`", E, (() => {
       let e = Window.focused();
       if (!e) return;
       o("============================================================="), o(e.hash() + " - " + e.app.name + " - " + e.title());
       let i = Storage.get("state");
       o(i), o("=============================================================")
     }))
   })();
   Phoenix.notify("All ok.")
   '';
 };
}




/* Add config for phoenix.debug.js:

(() => {
    "use strict";

    function e(e, i) {
        return e.x >= i.x && e.x <= i.x + i.width && e.y >= i.y && e.y <= i.y + i.height
    }
    const i = new Map;

    function t(e, i, t) {
        if (Array.isArray(e)) {
            const o = e.map((e => n(e, i, t)));
            return () => o.forEach((e => e()))
        }
        return n(e, i, t)
    }

    function n(e, t, n) {
        const o = new Key(e, t, n),
            s = function (e, i) {
                return e + i.sort().join()
            }(e, t);
        return i.set(s, o), () => function (e) {
            const t = i.get(e);
            t && (t.disable(), i.delete(e))
        }(s)
    }
    const o = Object.assign((function (...e) {
        e = e.map((e => s(e))), Phoenix.log(...e), console.trace(...e)
    }), {
        notify: (...e) => {
            e = e.map((e => s(e))), Phoenix.log(...e);
            const i = e.join(" ");
            Phoenix.notify(i), console.trace(...e)
        },
        noTrace: (...e) => {
            e = e.map((e => s(e))), Phoenix.log(...e), console.log(...e)
        }
    });

    function s(e) {
        if (e instanceof Error) {
            let i = "";
            if (e.stack) {
                const t = e.stack.trim().split("\n");
                t[0] += ` (:${e.line}:${e.column})`, i = "\n" + t.map((e => "\t at " + e)).join("\n")
            }
            return `\n${e.toString()}${i}`
        }
        switch (typeof e) {
        case "object":
            return "\n" + JSON.stringify(e, null, 2);
        case "function":
            return e.toString();
        default:
            return e
        }
    }
    var r;

    function d(e, i, t = 1, n) {
        const s = new Modal;
        s.text = i, s.duration = t, n && (s.icon = n),
            function (e, i) {
                ! function (e, i, t, n) {
                    const {
                        height: s,
                        width: r,
                        x: d,
                        y: a
                    } = e.frame(), l = i.visibleFrame();
                    e.origin = {
                        x: l.x + (l.width / t - r / 2),
                        y: l.y + (l.height / n - s / 2)
                    }, o(e.origin), e.show()
                }(e, i, 2, 1 + 1 / 3)
            }(s, e)
    }! function (e) {
        e[e.NorthWest = 0] = "NorthWest", e[e.NorthEast = 1] = "NorthEast", e[e.SouthWest = 2] = "SouthWest", e[e.SouthEast = 3] = "SouthEast"
    }(r || (r = {}));
    const a = App.get("Phoenix") || App.get("Phoenix (Debug)");
    class l {
        constructor(e, i) {
            this.workspace = null, this.screen = e, this.id = i
        }
        setWorkspace(e) {
            var i, t;
            (null === (t = null === (i = this.workspace) || void 0 === i ? void 0 : i.screen) || void 0 === t ? void 0 : t.id) === this.id && (this.workspace.screen = null);
            let n = u[e];
            this.workspace = n, n.screen = this
        }
        activateWorkspace(e) {
            var i;
            this.setWorkspace(e);
            let t = u[e];
            t.render(), k(t.windows[0]), Phoenix.log(this.id + " " + (null === (i = this.workspace) || void 0 === i ? void 0 : i.id)), this.vlog("Activated")
        }
        vlog(e, i = !0) {
            var t;
            i && (e += " " + (null === (t = this.workspace) || void 0 === t ? void 0 : t.id)), d(this.screen, e, 1, a && a.icon())
        }
        hideAllApps() {
            let e = this.screen.frame();
            this.screen.windows({
                visible: !0
            }).forEach((i => {
                e.y = e.height, i.setTopLeft(e)
            }))
        }
    }
    class h {
        constructor(e) {
            this.windows = [], this.screen = null, this.mainRatio_ = .8, this.id = e
        }
        set mainRatio(e) {
            this.mainRatio_ = Math.max(Math.min(e, .95), 0)
        }
        get mainRatio() {
            return this.mainRatio_
        }
        garbageCollect() {
            let e = new Set(Window.all().map((e => e.hash())));
            this.windows = this.windows.filter((i => e.has(i.hash())))
        }
        render() {
            if (this.garbageCollect(), !this.screen) throw new Error("render called without a screen: " + this.id);
            if (0 == this.windows.length) return void this.screen.hideAllApps();
            let e = this.screen.screen.flippedVisibleFrame(),
                i = e.width * this.mainRatio_;
            for (let t = this.windows.length - 1; t >= 0; t--) {
                let n = this.windows[t],
                    o = Object.assign({}, e);
                if (0 === t) this.windows.length > 1 && (o.width = i), n.setTopLeft(o), n.setSize(o);
                else {
                    let s = this.windows.length - 1;
                    o.x = e.x + i + 1, o.width = e.width - i, o.height = e.height / s, o.y = e.y + e.height / s * (t - 1) + 1, n.frame().width < o.width && n.setTopLeft(o), n.setSize(o), n.setTopLeft(o)
                }
                n.focus()
            }! function () {
                var e;
                let i = {
                    workspaces: [],
                    screens: [],
                    mouseMoveFocus: w,
                    autoAddWindows: f
                };
                for (let t of g) i.screens.push({
                    id: t.id,
                    workspace: null === (e = t.workspace) || void 0 === e ? void 0 : e.id
                });
                for (let e of u) i.workspaces.push({
                    id: e.id,
                    mainRatio: e.mainRatio,
                    windows: e.windows.map((e => e.hash()))
                });
                o("============SAVING============"), Storage.set("state", i)
            }()
        }
        spin() {
            let e = this.windows.shift();
            e && this.windows.push(e), o(this.windows.map((e => e.title()))), this.modal("Spinning "), this.render()
        }
        modal(e) {
            var i;
            this.screen && (null === (i = this.screen) || void 0 === i || i.vlog(e))
        }
        findIndexByHash(e) {
            return this.windows.findIndex((i => e === i.hash()))
        }
        findIndex(e) {
            return this.findIndexByHash(e.hash())
        }
        removeWindow(e) {
            let i = this.findIndex(e); - 1 != i && (this.windows.splice(i, 1), this.screen && this.render())
        }
        addWindow(e, i) {
            if (-1 != this.findIndex(e)) return void this.modal("Window already on ");
            let t = c.get(e.hash());
            t && t.removeWindow(e), i ? this.windows.unshift(e) : this.windows.push(e), c.set(e.hash(), this), this.screen && this.render(), this.modal("Adding window to ")
        }
    }
    let c = new Map,
        w = !1,
        f = !0;
    o(Window.all().map((e => e.hash() + " " + e.title())));
    let u = [];
    for (let e = 0; e <= 9; e++) u.push(new h(e));
    let p = Window.focused(),
        g = [];

    function v() {
        for (let e of u) e.screen = null;
        g = [];
        for (let [e, i] of Screen.all().entries()) g.push(new l(i, e));
        ! function () {
            let e = Window.all(),
                i = Storage.get("state");
            if (o("============LOADING============"), o(i), i) {
                for (let t of i.workspaces || []) {
                    o("Workspace " + t.id);
                    let i = u[t.id];
                    t.mainRatio && (i.mainRatio = t.mainRatio);
                    for (let n of t.windows) {
                        let t = e.find((e => e.hash() === n));
                        t && i.addWindow(t)
                    }
                }
                for (let e of i.screens || []) e.workspace && e.id < g.length && g[e.id].activateWorkspace(e.workspace);
                w = !!i.mouseMoveFocus, f = !!i.autoAddWindows
            }
        }(), g.sort(((e, i) => e.screen.frame().x - i.screen.frame().x));
        for (let [e, i] of g.entries()) i.workspace || i.activateWorkspace(e + 1);
        k(p)
    }

    function m() {
        let i = Mouse.location();
        return g.find((t => {
            let n = t.screen.flippedFrame();
            return e(i, n)
        })) || g[0]
    }

    function W(e) {
        let i = Window.focused();
        i && (u[e].addWindow(i, !0), y().render())
    }

    function k(e) {
        if (!e) return;
        e.focus();
        let i = e.frame();
        o("Focusing: " + e.title()), Mouse.move(A(i))
    }

    function x(e, i) {
        return (e + i) / 2
    }

    function A(e) {
        return {
            x: x(e.x, e.x + e.width),
            y: x(e.y, e.y + e.height)
        }
    }

    function y() {
        var e;
        let i = m();
        return o("getActiveWorkspace: screen: " + i.id + " workspace: " + (null === (e = i.workspace) || void 0 === e ? void 0 : e.id)), i.workspace
    }
    v();
    const S = ["alt"],
        E = [...S, "shift"];

    function M(e = 1) {
        let i = g.findIndex((e => e === m()));
        return g[Math.max(0, Math.min(g.length - 1, i + e))]
    }

    function P(e = 1) {
        var i;
        let t = M(e);
        (null === (i = t.workspace) || void 0 === i ? void 0 : i.windows.length) ? k(t.workspace.windows[0]): Mouse.move(A(t.screen.flippedFrame()))
    }
    Phoenix.set({
        daemon: !1,
        openAtLogin: !0
    }), t("right", S, (() => {
        P(1)
    })), t("right", E, (() => {
        let e = M().workspace;
        e && (W(e.id), k(e.windows[0]))
    })), t("left", S, (() => {
        P(-1)
    })), t("left", E, (() => {
        let e = M(-1).workspace;
        e && (W(e.id), k(e.windows[0]))
    })), t("down", S, (() => R())), t("j", S, (() => R())), t("up", S, (() => R(-1))), t("k", S, (() => R(-1))), t("h", S, (() => {
        y().mainRatio -= .1, y().render()
    })), t("h", E, (() => {
        y().mainRatio -= .01, y().render()
    })), t("l", S, (() => {
        y().mainRatio += .1, y().render()
    })), t("l", E, (() => {
        y().mainRatio += .01, y().render()
    })), t("return", S, (() => {
        let e = Window.focused();
        e && y().addWindow(e)
    })), t("return", E, (() => {
        let e = Window.focused();
        if (e)
            for (let i of e.app().windows()) c.has(i.hash()) || y().addWindow(i)
    })), t("delete", S, (() => {
        let e = Window.focused();
        e && y().removeWindow(e)
    })), t("c", E, (() => {
        let e = Window.focused();
        null == e || e.close()
    })), t("space", S, (() => {
        let e = Window.focused();
        if (!e) return;
        let i = u.find((i => e && -1 != i.findIndex(e)));
        i ? m().activateWorkspace(i.id) : m().vlog("No workspace for " + e.title(), !1)
    })), t("space", E, (() => {
        var e;
        let i = Window.focused();
        for (let i of g) null === (e = i.workspace) || void 0 === e || e.render(), i.vlog("Rerendered");
        k(i)
    })), t("r", S, (() => {
        y().spin()
    })), t("r", E, (() => {
        let e = Mouse.location(),
            i = g.map((e => e.workspace)),
            t = i.shift();
        i.push(t), o(i.map((e => e.id))), g.forEach(((e, t) => {
            o("setting SCREEN:" + e.id + " WINDOW: " + i[t].id), e.setWorkspace(i[t].id)
        })), g.forEach((e => {
            var i, t;
            o("rendering SCREEN:" + e.id + " WINDOW: " + (null === (i = e.workspace) || void 0 === i ? void 0 : i.id)), null === (t = e.workspace) || void 0 === t || t.render()
        })), Mouse.move(e)
    })), t("m", S, (() => {
        var e;
        w = e = !w, m().vlog("Mouse focus " + (e ? "enabled" : "disabled"), !1)
    })), t("a", S, (() => {
        var e;
        f = e = !f, m().vlog("Auto-add windows " + (e ? "enabled" : "disabled"), !1)
    }));
    for (let e = 0; e <= 9; e++) t(e.toString(), S, (() => {
        let i = u[e];
        if (i.screen) {
            let e = Window.focused(),
                t = m();
            return o(t.id), o(null == e ? void 0 : e.title()), i.screen !== t ? (i.screen.vlog("Here "), t.vlog("Already Showing " + i.id, !1)) : t.vlog("This is"), i.render(), void(t === i.screen ? (o(t.id), k(i.windows[0])) : (o(null == e ? void 0 : e.title()), k(e)))
        }
        m().activateWorkspace(e)
    })), t(e.toString(), E, (() => {
        W(e)
    }));

    function R(e = 1) {
        let i = Window.focused();
        if (!i) {
            let e = m();
            return void(e.workspace && e.activateWorkspace(e.workspace.id))
        }
        let t = i.hash(),
            n = c.get(t);
        if (!n) return;
        let o = n.windows;
        k(o[(n.findIndex(i) + e + o.length) % o.length])
    }
    Event.on("screensDidChange", (() => {
        v()
    })), Event.on("windowDidClose", (e => {
        let i = c.get(e.hash());
        i && (o("windowDidClose " + e.title() + " APPNAME: " + e.app().name() + " HASH: " + e.hash() + " removing from: " + i.id), i.removeWindow(e))
    })), Event.on("windowDidOpen", (e => {
        o("windowDidOpen " + e.title() + " APPNAME: " + e.app().name() + " HASH: " + e.hash() + " adding to: " + y().id), e.isVisible() && !c.get(e.hash()) && (o("windowDidOpen " + e.title() + " APPNAME: " + e.app().name() + " HASH: " + e.hash() + " adding to: " + y().id), "Phoenix" != e.app().name() && y().addWindow(e, !0))
    })), Event.on("appDidLaunch", (e => {
        o("appDidLaunch " + e.name() + " HASH: " + e.hash() + " adding to: " + y().id);
        for (let i of e.windows()) {
            if (!i.isVisible() || c.get(i.hash())) return;
            o("appDidLaunch " + i.title() + " APPNAME: " + i.app().name() + " HASH: " + i.hash() + " adding to: " + y().id), "Phoenix" != i.app().name() && y().addWindow(i, !0)
        }
    })), Event.on("appDidTerminate", (e => {
        for (let i of e.windows()) {
            let e = c.get(i.hash());
            if (!e) return;
            o("appDidTerminate " + i.title() + " APPNAME: " + i.app().name() + " HASH: " + i.hash() + " removing from: " + e.id), e.removeWindow(i)
        }
    })), Event.on("mouseDidMove", (i => {
        if (!w || i.modifiers.find((e => e === S[0]))) return;
        let t = Window.recent().find((t => e(i, t.frame())));
        null == t || t.focus()
    })), t("`", S, (() => {
        var e, i;
        for (let t of g)
            for (let n of (null === (e = t.workspace) || void 0 === e ? void 0 : e.windows) || []) {
                const e = new Modal;
                e.text = ((null === (i = t.workspace) || void 0 === i ? void 0 : i.id.toString()) || "") + " " + n.title(), e.duration = 3, e.icon = n.app().icon();
                let o = e.frame(),
                    s = A(n.frame()),
                    r = t.screen.flippedFrame(),
                    d = s.y - r.y;
                d = r.height - d, s.x -= o.width / 2, s.y = d - o.height + t.screen.frame().y, e.origin = s, e.show()
            }
    })), t("`", E, (() => {
        let e = Window.focused();
        if (!e) return;
        o("============================================================="), o(e.hash() + " - " + e.app.name + " - " + e.title());
        let i = Storage.get("state");
        o(i), o("=============================================================")
    }))
})();


*/
