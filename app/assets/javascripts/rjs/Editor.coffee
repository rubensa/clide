define ['ace/ace','IsabelleConnection','ace/search', 'ace/range', 'isabelle', 'commands'], (ace, IsabelleConnection, Search, Range, isabelle, commands) ->
  Search = Search.Search
  Range = Range.Range
  # options: user, project, path to set the routes
  class Editor extends Backbone.View
    # tag for new editors is <div>
    tagName: 'div'

    initialize: ->      
      @editorEl = $('<div class="editor"></div>')
      @$el.append(@editorEl)
      @model.on 'opened', @initModel
      @model.on 'close', @close

    initModel: (text) =>
      @ace = ace.edit @editorEl[0]
      @ace.setValue(text)

      # setup search
      commands.search.bind (text) => if @model.get 'active'
        @ace.findAll(text)

      oldPos = null
      pushPosTimeout = null

      @ace.on 'changeSelection', (args...) =>
        cursor = @ace.getCursorPosition()
        f = =>
          #r = @ace.renderer
          #pos = r.$cursorLayer.$pixelPos
          #offset = @editorEl.offset()          
          #pos.top += offset.top + r.lineHeight + 4 if offset?
          #pos.left += offset.left + (if r.showGutter then r.$gutter.offsetWidth else 0) if offset?
          #$('#completion').css pos
        setTimeout(f,50)
        unless cursor.row is oldPos?.row and cursor.column is oldPos?.column
          clearTimeout(pushPosTimeout)
          pushPosTimeout = setTimeout((=>
            oldPos = cursor
            @model.set 'cursor', cursor
            ),200)

      editSession = @ace.getSession()
      #@model.on 'change:output', (model, out) =>
      #  pos = editSession.documentToScreenPosition(out.line, 100)
      #  #@outputEl.css 
      #  #  top: pos.row
      #  #  left: pos.column
      #  @outputEl.html(out.message)
      range =
        start: 0
        end: 0
      editSession.on 'changeScrollTop', (args...) =>          
        start = @ace.getFirstVisibleRow()
        end = @ace.getLastVisibleRow()
        unless range.start is start and range.end is end
          range.start = start
          range.end = end
          @model.set 'perspective', range
      # Reset the undo manager so that the user cant undo the file load
      editSession.getUndoManager().reset()
      #session.setMode('ace/mode/isabelle')
      connect = new IsabelleConnection editSession, @model
      console.log connect
      # Clear selesction and move cursor to top (needs to be done for some reason)
      @ace.selection.clearSelection()
      @ace.gotoLine 0
      # Finally move focus to the editor
      @ace.focus()      
      @model.off 'opened', @initModel

    remove: =>
      console.log "release editor"
      @ace.destroy()
      super.remove()
    render: => @