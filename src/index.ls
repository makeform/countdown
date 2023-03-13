module.exports =
  pkg:
    name: "@makeform/input", extend: {name: "@makeform/base"}
    dependencies: [
      {name: "dayjs", path: "dayjs.min.js"}
      {name: "ldview"}
    ]
    i18n:
      "en":
        "closed": "closed"
        "remains": "remains"
        "day(s)": "day(s)"
        "D": "D"

      "zh-TW":
        "closed": "徵件已截止"
        "remains": "剩餘時間"
        "day(s)": "天"
        "D": "天"
  init: (opt) -> opt.pubsub.fire \init, mod: mod(opt)

mod = ({root, i18n, ctx, data}) ->
  {ldview, dayjs} = ctx
  mod =
    init: ->
      @i18n = i18n
      @info = {}
      @data = data or {}
      @deadline = (if (@data.config or {}).deadline => dayjs(that) else dayjs!).valueOf!
      @view = view = new ldview do
        root: root, ctx: @
        text:
          count: ({ctx}) ~> ctx.info.count
          hint: ({ctx}) ~> ctx.info.hint
          digit: ({node, ctx}) ~>
            digit = +node.getAttribute(\data-digit)
            ctx.info.hms[digit]
          day: ({ctx}) -> ctx.info.day or '0'

      @status 0
      mod.tick.apply @

    render: ->
      @deadline = (if (@_meta.config or {}).deadline => dayjs(that) else dayjs!).valueOf!

    tick: ->
      requestAnimationFrame ~> mod.tick.apply @
      now = Date.now!
      if @_last-render-time and (now - @_last-render-time) < 1000 => return
      remains = (@deadline - now)
      if remains < 0 => remains = 0
      ms = Math.round((remains % 1000)/100) % 10
      s = Math.floor(remains / 1000)
      [m,s] = [Math.floor(s / 60), (s % 60)]
      [h,m] = [Math.floor(m / 60), (m % 60)]
      [d,h] = [Math.floor(h / 24), (h % 24)]
      hms = "#{(''+h).padStart(2,'0')}#{(''+m).padStart(2,'0')}#{(''+s).padStart(2,'0')}"
      str = [
        (if !d => '' else "#d#{@i18n.t('day(s)')} ")
        (if h < 10 => "0" else ''), h, ':'
        (if m < 10 => "0" else ''), m, ':'
        (if s < 10 => "0" else ''), s, '.'
        ms, ("0" * (1 - ("#ms".length)))
      ].join('')
      @info =
        count: str
        hint: @i18n.t(if remains <= 0 => "closed" else "remains")
        hms: hms
        day: d or 0
      s = if remains <= 0 => 2 else 0
      if @status! != s => @status s
      @view.render!
      @_last-render-time = now - (now % 1000)
