define ['isabelle', 'commands', 'symbols'], (isabelle, commands, symbols) ->    
  # options: user, project, path to set the routes
  class Editor extends Backbone.View
    # tag for new editors is <div>
    tagName: 'div'

    initialize: ->
      @model.on 'opened', @initModel
      @model.on 'close', @close         

    changes: []

    pushTimeout: null

    pushChanges: =>
      isabelle.scala.call
        action: 'edit'
        data: 
          path:    @model.get 'path'
          version: @model.get 'currentVersion'
          changes: @changes.splice(0)          

    substitutions: []

    initModel: (text) =>
      currentLine = 0          

      @cm = new CodeMirror @el, 
        value: text
        indentUnit: 2
        lineNumbers: true
        mode: "isabelle"

      lastToken = null        
        
      @cm.on 'change', (editor,change) =>        
        unless editor.somethingSelected()          
          pos   = change.to          
          token = editor.getTokenAt(pos)
          marks = editor.findMarksAt(pos)
          for mark in marks 
            if mark.__special
              mark.clear()          
          from = 
            line: pos.line
            ch:   token.start
          to = 
            line: pos.line
            ch:   token.end
          if token.type? and (token.type.match(/special|symbol|abbrev|control|sub|sup|bold/))              
            sym = symbols[token.string]            
            control = false
            if token.type.match(/control/)                          
              sym = ""
              control = true
            if sym?
              widget = document.createElement('span')
              widget.appendChild(document.createTextNode(sym))
              widget.className = 'cm-' + token.type.replace(" "," cm-")
              @cm.markText from,to,          
                replacedWith: widget
                #clearOnEnter: control 
                __special:    true   
        clearTimeout(@pushTimeout)
        if @changes.length is 0 then @model.set 
          currentVersion: @model.get('currentVersion') + 1
          m.clear() for m in @markers
          @markers = []
        while change?
          @changes.push
            from: change.from
            to:   change.to
            text: change.text
          change = change.next          
        @pushTimeout = setTimeout(@pushChanges,700)

      @cm.on 'cursorActivity', (editor) =>        
        editor.removeLineClass(currentLine, 'background', 'current_line')
        cur = editor.getCursor()
        @model.set cursor: cur
        currentLine = editor.addLineClass(cur.line, 'background', 'current_line')

      @cm.on 'viewportChange', @updatePerspective

      cursor = @cm.getSearchCursor(/\\<(\^?[A-Za-z]+)>/)

      while cursor.findNext()
        sym = symbols[cursor.pos.match[0]]
        if sym?
          from = cursor.from()
          to   = cursor.to()
          text = document.createTextNode(sym)
          replacement = document.createElement("span")
          replacement.appendChild(text)
          replacement.className = "symbol"
          myWidget = replacement.cloneNode(true)
          @cm.markText(from, to, {
            replacedWith: myWidget,
            clearOnEnter: true
          })
        else if cursor.pos.match[0].indexOf('^') isnt -1
          from = cursor.from()
          to   = cursor.to()          
          replacement = document.createElement("span")
          replacement.appendChild('')
          replacement.className = "symbol"
          myWidget = replacement.cloneNode(true)
          @cm.markText(from, to, {
            replacedWith: myWidget,
            clearOnEnter: true
          })
          
      currentLine = @cm.addLineClass(0, 'background', 'current_line')

      @model.get('commands').forEach @includeCommand
      @model.get('commands').on('add', @includeCommand)
      @model.get('commands').on('change', @includeCommand)
      @model.on 'change:states', (m,states) =>
        for state, i in states
          cmd = @model.get('commands').getCommandAt(i)          
          #@cm.setMarker(i, null ,state)
      @model.on 'check', (content) =>
        if @cm.getValue() isnt content          
          console.error "cross check failed: ", @cm.getValue(), content
        else
          console.log "cross check passed"
      CodeMirror.simpleHint @cm, (args... )->
        console.log args ...

    updatePerspective: (editor, start, end) =>      
      @model.set
        perspective:
          start: start
          end:   end    

    markers: []

    includeCommand: (cmd) => if cmd.get 'version' is @model.get('currentVersion')
      console.log 'linewidget'
      out = cmd.get 'output'
      lineWidget = document.createElement('span')
      lineWidget.appendChild(document.createTextNode(out))
      range = cmd.get 'range'
      @cm.addLineWidget(range.end,lineWidget)

      # #console.log "cmd: #{cmd.get 'version'}, model: #{@model.get 'currentVersion' }"      
      # vp = @cm.getViewport()
      # #console.log vp
      # range  = cmd.get 'range'
      # if vp.from >= range.end || vp.to <= range.start
      #   return      
      # length = range.end - range.start
      # for line, i in cmd.get 'tokens'
      #   l = i + range.start
      #   if l >= vp.from && l <= vp.to
      #     p = 0
      #     for tk in line
      #       from = 
      #         line: l
      #         ch: p
      #       p += tk.value.length
      #       unless (tk.type is "text" or tk.type is "")
      #         to =
      #           line: l
      #           ch: p              
      #         @markers.push(@cm.markText(from,to,"cm-#{tk.type.replace(/\./g,' cm-')}"))              

    remove: =>
      @model.get('commands').off()
      super.remove()

    render: => @