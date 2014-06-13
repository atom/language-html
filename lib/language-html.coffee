Range = require( 'node_modules/text-buffer/lib/range' )

SELF_CLOSING_TAGS=["area","base","br","col","command","embed","hr","img",
  "input","keygen","link","meta","param","source","track","wbr"]

module.exports =
  activate: ->
    atom.workspaceView.command "language-html:close-tag", => @closeTag()

  lastTagNotClosedInFragment: (fragment) ->
    stack = []
    matchExpr = /<(\w+)|<\/(\w*)/
    match = fragment.match(matchExpr)
    while match
      if SELF_CLOSING_TAGS.indexOf(match[1]) < 0
        topElem = stack[stack.length-1]

        if match[2] && topElem == match[2]
          stack.pop()
        else
          stack.push match[1]

      fragment = fragment.substr(match.index + match[0].length)
      match = fragment.match(matchExpr)

    stack[ stack.length - 1 ]

  tagDoesNotCloseInFragment: ( tag, fragment ) ->
    stack = [tag]
    matchExpr = new RegExp( "<(" + tag + ")|<\/(" + tag + ")" )
    match = fragment.match( matchExpr )
    while match && stack.length > 0
      topElem = stack[stack.length-1]
      if match[2] && topElem == match[2]
        stack.pop()
      else
        stack.push match[1]

      fragment = fragment.substr( match.index + match[0].length )
      match = fragment.match(matchExpr)

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
