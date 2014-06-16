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

  describe 'lastTagNotClosedInFragment', ->
    it 'returns the outermost tag not closed in an HTML fragment', ->
      fragment = "<html><head></head><body><h1><p></p>"
      tag = langHtml.lastTagNotClosedInFragment(fragment)
      expect(tag).toBe("h1")

    it 'is not confused by tag attributes', ->
      fragment = '<html><head></head><body class="c"><h1 class="p"><p></p>'
      tag = langHtml.lastTagNotClosedInFragment(fragment)
      expect(tag).toBe("h1")

  describe 'tagDoesNotCloseInFragment', ->
    it 'returns true if the given tag is not closed in the given fragment', ->
      fragment = "</other1></other2></html>"
      expect(langHtml.tagDoesNotCloseInFragment("body", fragment)).toBe(true)

    it 'returns false if the given tag is closed in the given fragment', ->
      fragment = "</other1></body></html>"
      expect(langHtml.tagDoesNotCloseInFragment("body", fragment)).toBe(false)

    it 'returns true even if the given tag is re-opened and re-closed', ->
      fragment = "<other> </other><body></body><html>"
      expect(langHtml.tagDoesNotCloseInFragment("body", fragment)).toBe(true)

    it 'correctly false even if the given tag is re-opened and re-closed before closing', ->
      fragment = "<other> </other><body></body></body><html>"
      expect(langHtml.tagDoesNotCloseInFragment("body", fragment)).toBe(false)

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
