{ Point, Range, WorkspaceView } = require 'atom'
path = require('path')
langHtml = require '../lib/language-html'

describe 'language-html', ->
  describe 'parseFragment', ->
    fragment = ""

    beforeEach ->
      fragment = "<html><head><body></body>"

    it 'returns the last not closed elem in fragment, matching a given pattern', ->
      stack = langHtml.parseFragment fragment, [], /<(\w+)|<\/(\w*)/, -> true
      expect(stack[stack.length-1]).toBe("head")

    it 'stops when cond become true',  ->
      stack = langHtml.parseFragment fragment, [], /<(\w+)|<\/(\w*)/, -> false
      expect(stack.length).toBe(0)

    it 'uses the given match expression to match tags', ->
      stack = langHtml.parseFragment fragment, [], /<(body)|(notag)/, -> true
      expect(stack[stack.length-1]).toBe("body")

  describe 'tagsNotClosedInFragment', ->
    it 'returns the outermost tag not closed in an HTML fragment', ->
      fragment = "<html><head></head><body><h1><p></p>"
      tags = langHtml.tagsNotClosedInFragment(fragment)
      expect(tags).toEqual(['html','body','h1'])

    it 'is not confused by tag attributes', ->
      fragment = '<html><head></head><body class="c"><h1 class="p"><p></p>'
      tags = langHtml.tagsNotClosedInFragment(fragment)
      expect(tags).toEqual(['html','body','h1'])

  describe 'tagDoesNotCloseInFragment', ->
    it 'returns true if the given tag is not closed in the given fragment', ->
      fragment = "</other1></other2></html>"
      expect(langHtml.tagDoesNotCloseInFragment("body", fragment)).toBe(true)

    it 'returns false if the given tag is closed in the given fragment', ->
      fragment = "</other1></body></html>"
      expect(langHtml.tagDoesNotCloseInFragment(["body"], fragment)).toBe(false)

    it 'returns true even if the given tag is re-opened and re-closed', ->
      fragment = "<other> </other><body></body><html>"
      expect(langHtml.tagDoesNotCloseInFragment(["body"], fragment)).toBe(true)

    it 'returns false even if the given tag is re-opened and re-closed before closing', ->
      fragment = "<other> </other><body></body></body><html>"
      expect(langHtml.tagDoesNotCloseInFragment(["body"], fragment)).toBe(false)

  describe 'closingTagForFragments', ->
    it 'returns the last opened in preFragment tag that is not closed in postFragment', ->
      preFragment = "<html><head></head><body><h1></h1><p>"
      postFragment = "</body></html>"
      expect(langHtml.closingTagForFragments(preFragment, postFragment)).toBe("p")

    it 'correctly handles empty postFragment', ->
      preFragment = "<html><head></head><body><h1></h1><p>"
      postFragment = ""
      expect(langHtml.closingTagForFragments(preFragment, postFragment)).toBe("p")

    it 'returns null if there is no open tag to be closed', ->
      preFragment = "<html><head></head><body><h1></h1><p>"
      postFragment = "</p></body></html>"
      expect(langHtml.closingTagForFragments(preFragment, postFragment)).toBe(null)

  describe 'closeTag', ->
    beforeEach ->
      atom.workspaceView = new WorkspaceView();
      atom.project.setPath path.join(__dirname, 'fixtures')
      atom.workspaceView.openSync('sample.html')
      atom.workspaceView.attachToDom();
      @editorView = atom.workspaceView.getActiveView();
      @editor = @editorView.getEditor()
      atom.packages.activatePackage("language-html")

    it 'closes the first non closed tag', ->
      @editor.setCursorBufferPosition(new Point(5,14))
      @editorView.trigger('language-html:close-tag')

      cursorPos = @editor.getCursorBufferPosition()
      insertedText = @editor.getTextInRange( new Range([5,14], [5,18]) )

      expect( cursorPos ).toEqual( new Point(5, 18) )
      expect( insertedText ).toEqual('</a>')

    it 'closes the following unclosed tags if called repeatedly', ->
      @editor.setCursorBufferPosition(new Point(5,14))
      @editorView.trigger('language-html:close-tag')
      @editorView.trigger('language-html:close-tag')

      cursorPos = @editor.getCursorBufferPosition()
      insertedText = @editor.getTextInRange( new Range([5,18], [5,22]) )

      expect( cursorPos ).toEqual( new Point(5, 22) )
      expect( insertedText ).toEqual('</p>')

    it 'does not get confused in case of nested identical tags -- tag closing', ->
      @editor.setCursorBufferPosition(new Point(13,11))
      @editorView.trigger('language-html:close-tag')

      cursorPos = @editor.getCursorBufferPosition()
      insertedText = @editor.getTextInRange( new Range([13,10], [13,16]) )

      expect( cursorPos ).toEqual( new Point(13, 16) )
      expect( insertedText ).toEqual('</div>')

      @editorView.trigger('language-html:close-tag')
      cursorPos = @editor.getCursorBufferPosition()
      expect( cursorPos ).toEqual( new Point(13,16) )


    it 'does not get confused in case of nested identical tags -- tag not closing', (done)->
      @editor.setCursorBufferPosition(new Point(13,11))
      @editorView.trigger('language-html:close-tag')

      cursorPos = @editor.getCursorBufferPosition()
      insertedText = @editor.getTextInRange( new Range([13,10], [13,16]) )

      expect( cursorPos ).toEqual( new Point(13, 16) )
      expect( insertedText ).toEqual('</div>')

      @editorView.trigger('language-html:close-tag')
      cursorPos = @editor.getCursorBufferPosition()
      expect( cursorPos ).toEqual( new Point(13,16) )

    # it 'does not get confused in case of nested identical tags -- tag not closing', ->
    #   @editor.setCursorBufferPosition(new Point(13,11))
    #   @editorView.trigger('language-html:close-tag')
    #   @editorView.trigger('language-html:close-tag')
    #
    #   cursorPos = @editor.getCursorBufferPosition()
    #   expect( cursorPos ).toEqual( new Point(13,16) )
