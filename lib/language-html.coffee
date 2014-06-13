Range = require( 'node_modules/text-buffer/lib/range' )

SELF_CLOSING_TAGS=["area","base","br","col","command","embed","hr","img",
  "input","keygen","link","meta","param","source","track","wbr"]

module.exports =
  activate: ->
    atom.workspaceView.command "language-html:close-tag", => @closeTag()

  parseFragment: (fragment, stack, matchExpr, cond) ->
    match = fragment.match(matchExpr)
    while match && cond(stack)
      if SELF_CLOSING_TAGS.indexOf(match[1]) < 0
        topElem = stack[stack.length-1]

        if match[2] && topElem == match[2]
          stack.pop()
        else
          stack.push match[1]

      fragment = fragment.substr(match.index + match[0].length)
      match = fragment.match(matchExpr)

    stack


  lastTagNotClosedInFragment: (fragment) ->
    stack = []
    matchExpr = /<(\w+)|<\/(\w*)/
    stack = @parseFragment( fragment, stack, matchExpr, (x) -> true )

    stack[ stack.length - 1 ]

  tagDoesNotCloseInFragment: ( tag, fragment ) ->
    stack = [tag]
    matchExpr = new RegExp( "<(" + tag + ")|<\/(" + tag + ")" )
    stack = @parseFragment( fragment, stack, matchExpr, (s) -> s.length > 0 )

    stack.length > 0

  closeTag: ->
    editor = atom.workspace.getActiveEditor()
    curPos = editor.getCursorBufferPosition()
    textLimits = editor.getBuffer().getRange()
    preFragment = editor.getTextInBufferRange( new Range( textLimits.start, curPos) )
    postFratment = editor.getTextInBufferRange( new Range( curPos, textLimits.end ) )

    tag = @lastTagNotClosedInFragment( preFragment )
    if @tagDoesNotCloseInFragment( tag, postFratment )
      editor.insertText( "</" + tag + ">" )
