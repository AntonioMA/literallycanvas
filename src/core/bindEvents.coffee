coordsForTouchEvent = (el, e) ->
  tx = e.changedTouches[0].clientX
  ty = e.changedTouches[0].clientY
  p = el.getBoundingClientRect()
  return [tx - p.left, ty - p.top]


position = (el, e) ->
  p = el.getBoundingClientRect()
  {
    left: e.clientX - p.left,
    top: e.clientY - p.top,
  }


buttonIsDown = (e) ->
  if e.buttons?
    return e.buttons == 1
  else
    return e.which > 0


module.exports = bindEvents = (lc, canvas, panWithKeyboard = false) ->
  _document = canvas.getRootNode() || document;
  unsubs = []

  mouseMoveListener = (e) =>
    e.preventDefault()
    p = position(canvas, e)
    lc.pointerMove(p.left, p.top)

  mouseUpListener = (e) =>
    e.preventDefault()
    canvas.onselectstart = -> true # enable selection while dragging
    p = position(canvas, e)
    lc.pointerUp(p.left, p.top)
    _document.removeEventListener 'mousemove', mouseMoveListener
    _document.removeEventListener 'mouseup', mouseUpListener

    canvas.addEventListener 'mousemove', mouseMoveListener

  canvas.addEventListener 'mousedown', (e) =>
    return if e.target.tagName.toLowerCase() != 'canvas'

    down = true
    e.preventDefault()
    canvas.onselectstart = -> false # disable selection while dragging
    p = position(canvas, e)
    lc.pointerDown(p.left, p.top)

    canvas.removeEventListener 'mousemove', mouseMoveListener
    _document.addEventListener 'mousemove', mouseMoveListener
    _document.addEventListener 'mouseup', mouseUpListener


  touchMoveListener = (e) ->
    e.preventDefault()
    lc.pointerMove(coordsForTouchEvent(canvas, e)...)

  touchEndListener = (e) ->
    e.preventDefault()
    lc.pointerUp(coordsForTouchEvent(canvas, e)...)
    _document.removeEventListener 'touchmove', touchMoveListener
    _document.removeEventListener 'touchend', touchEndListener
    _document.removeEventListener 'touchcancel', touchEndListener

  canvas.addEventListener 'touchstart', (e) ->
    return if e.target.tagName.toLowerCase() != 'canvas'
    e.preventDefault()
    if e.touches.length == 1
      lc.pointerDown(coordsForTouchEvent(canvas, e)...)
      _document.addEventListener 'touchmove', touchMoveListener
      _document.addEventListener 'touchend', touchEndListener
      _document.addEventListener 'touchcancel', touchEndListener
    else
      lc.pointerMove(coordsForTouchEvent(canvas, e)...)

  if panWithKeyboard
    console.warn("Keyboard panning is deprecated.")
    listener = (e) ->
      switch e.keyCode
        when 37 then lc.pan -10, 0
        when 38 then lc.pan 0, -10
        when 39 then lc.pan 10, 0
        when 40 then lc.pan 0, 10
      lc.repaintAllLayers()

    _document.addEventListener 'keydown', listener
    unsubs.push -> document.removeEventListener(listener)

  -> f() for f in unsubs
