Phoenix.notify("Phoenix config loading")

Phoenix.set({
  daemon: false,
  openAtLogin: true
})
let log = function (o, label = "obj: ") {
  Phoenix.log(`${(new Date()).toISOString()}:: ${label} =>`)
  Phoenix.log(JSON.stringify(o))
}
_.mixin({
  flatmap(list, iteratee, context) {
    return _.flatten(_.map(list, iteratee, context))
  }
})

GAPS = 13

MARGIN_X = GAPS // gaps!
MARGIN_Y = GAPS // gaps!
GRID_WIDTH = 5 // or 16 - 
GRID_HEIGHT = 3 // by 9 aspect ratio! need to be able to detect screen ration...
GRID_BAR = 40 // Give space for the sketchybar on top.
focused = () => Window.focused()

function visible() { 
  return Window.all().filter( w => {
    if (w != undefined) { 
      return w.isVisible()
    } else {
      return false
    }
  })
}

Window.prototype.screenFrame = function(screen) {
  return (screen != null ? screen.flippedVisibleFrame() : void 0) || this.screen().flippedVisibleFrame()
}

Window.prototype.fullGridFrame = function() {
  return this.calculateGrid({y: 0, x: 0, width: 1, height: 1})
}
function snapAllToGrid() { _.map(visible(), win => win.snapToGrid()) }
changeGridWidth = n => {
  GRID_WIDTH = Math.max(1, GRID_WIDTH + n)
  Phoenix.notify(`grid is ${GRID_WIDTH} tiles wide`)
  snapAllToGrid()
  return GRID_WIDTH
}

changeGridHeight = n => {
  GRID_HEIGHT = Math.max(1, GRID_HEIGHT + n)
  Phoenix.notify(`grid is ${GRID_HEIGHT} tiles high`)
  snapAllToGrid()
  return GRID_HEIGHT
}
Window.prototype.getBoxSize = function() {
  return [this.screenFrame().width / GRID_WIDTH, 
          this.screenFrame().height / GRID_HEIGHT]
}
Window.prototype.getGrid = function() {
  let frame = this.frame()
  let [boxHeight, boxWidth] = this.getBoxSize() 
  let grid = {
    y: Math.round((frame.y - this.screenFrame().y) / boxHeight),
    x: Math.round((frame.x - this.screenFrame().x) / boxWidth),
    width: Math.max(1, Math.round(frame.width / boxWidth)),
    height: Math.max(1, Math.round(frame.height / boxHeight))
  }
  log(`Window grid: ${grid}`)
  return grid
}
Window.prototype.setGrid = function({y, x, width, height}, screen) {
  let gridHeight, gridWidth
  screen = screen || focused().screen()
  gridWidth = this.screenFrame().width / GRID_WIDTH
  gridHeight = this.screenFrame().height / GRID_HEIGHT
  return this.setFrame({
    y: ((y * gridHeight) + this.screenFrame(screen).y) + MARGIN_Y,
    x: ((x * gridWidth) + this.screenFrame(screen).x) + MARGIN_X,
    width: (width * gridWidth) - (MARGIN_X * 2.0),
    height: (height * gridHeight) - (MARGIN_Y * 2.0)
  })
}
Window.prototype.snapToGrid = function() {
  if (this.isNormal()) {
    return this.setGrid(this.getGrid())
  }
}
Window.prototype.calculateGrid = function({x, y, width, height}) {
  return {
    y: Math.round(y * this.screenFrame().height) + MARGIN_Y + this.screenFrame().y,
    x: Math.round(x * this.screenFrame().width) + MARGIN_X + this.screenFrame().x,
    width: Math.round(width * this.screenFrame().width) - 2.0 * MARGIN_X,
    height: Math.round(height * this.screenFrame().height) - 2.0 * MARGIN_Y
  }
}
Window.prototype.proportionWidth = function() {
  let s_w, w_w
  s_w = this.screenFrame().width
  w_w = this.frame().width
  return Math.round((w_w / s_w) * 10) / 10
}
Window.prototype.toGrid = function({x, y, width, height}) {
  let rect = this.calculateGrid({x, y, width, height})
  return this.setFrame(rect)
}
Window.prototype.topRight = function() {
  return {
    x: this.frame().x + this.frame().width,
    y: this.frame().y
  }
}
Window.prototype.toLeft = function() {
  return _.filter(this.neighbors('west'), function(win) {
    return win.topLeft().x < this.topLeft().x - 10
  })
}
Window.prototype.toRight = function() {
  return _.filter(this.neighbors('east'), function(win) {
    return win.topRight().x > this.topRight().x + 10
  })
}

Window.prototype.info = function() {
  let f = this.frame()
  return `[${this.app().processIdentifier()}] ${this.app().name()} : ${this.title()}\n{x:${f.x}, y:${f.y}, width:${f.width}, height:${f.height}}\n`
}
lastFrames = {}
Window.prototype.toFullScreen = function(toggle = true) {
  if (!_.isEqual(this.frame(), this.fullGridFrame())) {
    this.rememberFrame()
    return this.toGrid({y: 0, x: 0, width: 1, height: 1})
  } else if (toggle && lastFrames[this.uid()]) {
    this.setFrame(lastFrames[this.uid()])
    return this.forgetFrame()
  }
}
Window.prototype.uid = function() {
  return `${this.app().name()}::${this.title()}`
}

Window.prototype.rememberFrame = function() {
  return lastFrames[this.uid()] = this.frame()
}

Window.prototype.forgetFrame = function() {
  return delete lastFrames[this.uid()]
}
Window.prototype.togglingWidth = function() {
  switch (this.proportionWidth()) {
    case 0.8:
      return 0.5
    case 0.5:
      return 0.3
    default:
      return 0.8
  }
}
Window.prototype.toTopHalf = function() {
  return this.toGrid({x: 0, y: 0, width: 1, height: 0.5})
}

Window.prototype.toBottomHalf = function() {
  return this.toGrid({x: 0, y: 0.5, width: 1, height: 0.5})
}

Window.prototype.toLeftHalf = function() {
  return this.toGrid({x: 0, y: 0, width: 0.5, height: 1})
}

Window.prototype.toRightHalf = function() {
  return this.toGrid({x: 0.5, y: 0, width: 0.5, height: 1})
}

Window.prototype.toLeftToggle = function() {
  return this.toGrid({
    x: 0,
    y: 0,
    width: this.togglingWidth(),
    height: 1
  })
}

Window.prototype.toRightToggle = function() {
  return this.toGrid({
    x: 1 - this.togglingWidth(),
    y: 0,
    width: this.togglingWidth(),
    height: 1
  })
}
Window.prototype.toTopRight = function() {
  return this.toGrid({x: 0.5, y: 0, width: 0.5, height: 0.5})
}

Window.prototype.toBottomRight = function() {
  return this.toGrid({x: 0.5, y: 0.5, width: 0.5, height: 0.5})
}

Window.prototype.toTopLeft = function() {
  return this.toGrid({x: 0, y: 0, width: 0.5, height: 0.5})
}

Window.prototype.toBottomLeft = function() {
  return this.toGrid({x: 0, y: 0.5, width: 0.5, height: 0.5})
}
Window.prototype.toCenterWithBorder = function(border = 1) { // HUH?
  let [boxWidth, boxHeight] = this.getBoxSize()
  let rect = { 
               x: border,
               y: border, 
               width: GRID_WIDTH  - (border * 2),
               height: GRID_HEIGHT - (border * 2)
             }
  this.setGrid(rect)
}
windowLeftOneColumn = () => {
  let frame = focused().getGrid()
  frame.x = Math.max(frame.x - 1, 0)
  return focused().setGrid(frame)
  Phoenix.notify("windowLeftOneColumn")
}

windowDownOneRow = () => {
  let frame = focused().getGrid()
  frame.y = Math.min(Math.floor(frame.y + 1), GRID_HEIGHT - 1)
  return focused().setGrid(frame)
  Phoenix.notify("windowDownOneRow")
}

windowUpOneRow = () => {
  let frame = focused().getGrid()
  frame.y = Math.max(Math.floor(frame.y - 1), 0)
  return focused().setGrid(frame)
  Phoenix.notify("windowUpOneRow")
}

windowRightOneColumn = () => {
  let frame = focused().getGrid()
  frame.x = Math.min(frame.x + 1, GRID_WIDTH - frame.width)
  return focused().setGrid(frame)
  Phoenix.notify("windowRightOneColumn")
}
windowGrowOneGridColumn = () => {
  let frame = focused().getGrid()
  frame.width = Math.min(frame.width + 1, GRID_WIDTH - frame.x)
  return focused().setGrid(frame)
}

windowShrinkOneGridColumn = () => {
  let frame = focused().getGrid()
  frame.width = Math.max(frame.width - 1, 1)
  return focused().setGrid(frame)
}

windowGrowOneGridRow = () => {
  let frame = focused().getGrid()
  frame.height = Math.min(frame.height + 1, GRID_HEIGHT)
  return focused().setGrid(frame)
}

windowShrinkOneGridRow = () => {
  let frame = focused().getGrid()
  frame.height = Math.max(frame.height - 1, 1)
  return focused().setGrid(frame)
}
windowToFullHeight = () => {
  let frame = focused().getGrid()
  frame.y = 0
  frame.height = GRID_HEIGHT
  return focused().setGrid(frame)
}
windowToFullWidth = () => {
  let frame = focused().getGrid()
  frame.x = 0
  frame.width = GRID_WIDTH
  return focused().setGrid(frame)
}
moveWindowToNextScreen = () => focused().setGrid(focused().getGrid(), focused().screen().next())
moveWindowToPreviousScreen = () => focused().setGrid(focused().getGrid(), focused().screen().previous())
App.prototype.firstWindow = function() {
  return this.all({
    visible: true
  })[0]
}
App.allWithName = name => _.filter(App.all(), a => a.name() === name)

App.byName = name => {
  let app = _.first(App.allWithName(name))
  app.show()
  return app
}
App.focusOrStart = name => {
  let apps = App.allWithName(name)
  
  if (_.isEmpty(apps)) {
    App.launch(name)
  }
  
  let windows = _.flatmap(apps, x => x.windows())
  let activeWindows = _.reject(windows, win => win.isMinimized())
  
  if (_.isEmpty(activeWindows)) {
    App.launch(name)
  }
  
  return _.each(activeWindows, win => win.focus())
}

ALACRITTY = "Alacritty"
EMACS = "Emacs"
FINDER = "Finder"
BRAVE = "Brave Browser"
let showAppName = () => {
  let name = focused().app().name()
  let frame = focused().screenFrame()
  let modal = Modal.build({
    duration: 2,
    text: `App: ${name}`
  })
  modal.origin = {
    x: (frame.width / 2) - modal.frame().width / 2,
    y: frame.height - 100
  }
  modal.show()
}
keys = []
const bind_key = (key, description, modifier, fn) => keys.push(Key.on(key, modifier, fn))
const mash = 'cmd-alt-ctrl'.split('-')
const smash = 'cmd-alt-ctrl-shift'.split('-')
bind_key('up', 'Top Half', mash, () => focused().toTopHalf())
bind_key('down', 'Bottom Half', mash, () => focused().toBottomHalf())
bind_key('left', 'Left side toggle', mash, () => focused().toLeftToggle())
bind_key('right', 'Right side toggle', mash, () => focused().toRightToggle())
bind_key('C', 'Center with border', mash, () => focused().toCenterWithBorder(1))
bind_key('Q', 'Top Left', mash, () => focused().toTopLeft())
bind_key('A', 'Bottom Left', mash, () => focused().toBottomLeft())
bind_key('W', 'Top Right', mash, () => focused().toTopRight())
bind_key('S', 'Bottom Right', mash, () => focused().toBottomRight())
bind_key('z', 'Left Half', mash, () => focused().toLeftHalf())
bind_key('x', 'Right Half', mash, () => focused().toRightHalf())
bind_key('F', 'Maximize Window', mash, () => focused().toMaximizeScreen())
bind_key('F', 'Fullscreen Window', smash, () => focused().toFullScreen())
bind_key('1', 'Show App Name', mash, showAppName) 
bind_key('E', 'Launch Emacs', mash, () => App.focusOrStart(EMACS))
bind_key('T', 'Launch Alacritty', mash, () => App.focusOrStart(ALACRITTY))
bind_key('space', 'Launch Browser', mash, () => App.focusOrStart(BRAVE))
//bind_key('F', 'Launch Finder', mash, () => App.focusOrStart(FINDER))
bind_key('N', 'To Next Screen', mash, moveWindowToNextScreen)
bind_key('P', 'To Previous Screen', mash, moveWindowToPreviousScreen)
bind_key('=', 'Increase Grid Columns', mash, () => changeGridWidth(+1))
bind_key('-', 'Reduce Grid Columns', mash, () => changeGridWidth(-1))
bind_key(']', 'Increase Grid Rows', mash, () => changeGridHeight(+1))
bind_key('[', 'Reduce Grid Rows', mash, () => changeGridHeight(-1))
bind_key(';', 'Snap focused to grid', mash, () => focused().snapToGrid())
bind_key("'", 'Snap all to grid', mash, function(){ visible().map(win => win.snapToGrid()) })
bind_key('H', 'Move Grid Left', mash, windowLeftOneColumn)
bind_key('J', 'Move Grid Down', mash, windowDownOneRow)
bind_key('K', 'Move Grid Up', mash, windowUpOneRow)
bind_key('L', 'Move Grid Right', mash, windowRightOneColumn)
bind_key('6', 'Move Grid Left', mash, windowLeftOneColumn)
bind_key('7', 'Move Grid Down', mash, windowDownOneRow) //works
bind_key('8', 'Move Grid Up', mash, windowUpOneRow) //works
bind_key('9', 'Move Grid Right', mash, windowRightOneColumn)
bind_key('U', 'Window Full Height', mash, windowToFullHeight) 
bind_key('Y', 'Window Full Width', mash, windowToFullWidth)
bind_key('I', 'Shrink by One Column', mash, windowShrinkOneGridColumn)
bind_key('O', 'Grow by One Column', mash, windowGrowOneGridColumn)
bind_key(',', 'Shrink by One Row', mash, windowShrinkOneGridRow)
bind_key('.', 'Grow by One Row', mash, windowGrowOneGridRow)
//bind_key('M', 'Markdown Editing', mash, () => {
//  App.focusOrStart(FIREFOX) 
//  focused().toRightHalf()
//  App.focusOrStart(EMACS)
//  focused().toLeftHalf()
//})

//bind_key('M', 'Exit Markdown Editing', smash, () => {
//  App.focusOrStart(FIREFOX)
//  focused().toFullScreen(false)
//  App.focusOrStart(EMACS)
//  focused().toFullScreen(false)
//})
Phoenix.notify("All ok.")