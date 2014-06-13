Range = require( 'node_modules/text-buffer/lib/range' )

SELF_CLOSING_TAGS=["area","base","br","col","command","embed","hr","img",
  "input","keygen","link","meta","param","source","track","wbr"]

module.exports =
  activate: ->
    atom.workspaceView.command "language-html:close-tag", => @closeTag()

  # Parses a fragment of html returning the stack (i.e., an array) of open tags
  #
  # fragment  - the fragment of html to be analysed
  # stack     - an array to be populated (can be non-empty)
  # matchExpr - a RegExp describing how to match opening/closing tags
  #    the opening/closing descriptions must be captured subexpressions
  #    so that the code can refer to match[1] to check if an opening tag
  #    has been found, and to match[2] to check if a closing tag has been
  #    found
  # cond      - a condition to be checked at each iteration. If the function
  #    returns false the processing is immediately interrupted. When called
  #    the current stack is provided to the function.
  #
  # Returns an array of strings. Each string is a tag that is still to be closed
  # (the most recent non closed tag is at the end of the array).
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

  # Parses the given fragment of html code returning the last unclosed tag.
  #
  # fragment - a string containing a fragment of html code.
  #
  # Returns a string with the name of the most recent unclosed tag.
  lastTagNotClosedInFragment: (fragment) ->
    stack = []
    matchExpr = /<(\w+)|<\/(\w*)/
    stack = @parseFragment( fragment, stack, matchExpr, (x) -> true )

    stack[ stack.length - 1 ]

  # Parses the given fragment of html code and returns true if the given tag
  # has a matching closing tag in it. If tag is reopened and reclosed in the
  # given fragment then the end point of that pair does not count as a matching
  # closing tag.
  tagDoesNotCloseInFragment: ( tag, fragment ) ->
    stack = [tag]
    matchExpr = new RegExp( "<(" + tag + ")|<\/(" + tag + ")" )
    stack = @parseFragment( fragment, stack, matchExpr, (s) -> s.length > 0 )

    stack.length > 0

  # Parses preFragment and postFragment returning the last open tag in
  # preFragment that is not closed in postFragment.
  #
  # Returns a tag name or null if it can't find it.
  closingTagForFragments: (preFragment, postFragment) ->
    tag = @lastTagNotClosedInFragment( preFragment )
    if @tagDoesNotCloseInFragment( tag, postFragment )
      return tag
    else
      return null

  # Insert at the current cursor position a closing tag if there exists an
  # open tag that is not closed afterwards.
  closeTag: ->
    editor = atom.workspace.getActiveEditor()
    curPos = editor.getCursorBufferPosition()
    textLimits = editor.getBuffer().getRange()
    preFragment = editor.getTextInBufferRange( new Range( textLimits.start, curPos) )
    postFratment = editor.getTextInBufferRange( new Range( curPos, textLimits.end ) )

    tag = closingTagForFragments(preFragment, postFragment)
    editor.insertText( "</" + tag + ">" ) if tag?
