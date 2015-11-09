describe 'HTML grammar', ->
  grammar = null

  beforeEach ->
    waitsForPromise ->
      atom.packages.activatePackage('language-html')

    waitsForPromise ->
      atom.packages.activatePackage('language-coffee-script')

    runs ->
      grammar = atom.grammars.grammarForScopeName('text.html.basic')

  it 'parses the grammar', ->
    expect(grammar).toBeTruthy()
    expect(grammar.scopeName).toBe 'text.html.basic'

  describe 'meta.scope.outside-tag scope', ->
    it 'tokenizes an empty file', ->
      lines = grammar.tokenizeLines ''
      expect(lines[0][0]).toEqual value: '', scopes: ['text.html.basic']

    it 'tokenizes a single < as without freezing', ->
      lines = grammar.tokenizeLines '<'
      expect(lines[0][0]).toEqual value: '<', scopes: ['text.html.basic']

      lines = grammar.tokenizeLines ' <'
      expect(lines[0][0]).toEqual value: ' <', scopes: ['text.html.basic']

    it 'tokenizes <? without locking up', ->
      lines = grammar.tokenizeLines '<?'
      expect(lines[0][0]).toEqual value: '<?', scopes: ['text.html.basic']

    it 'tokenizes >< as html without locking up', ->
      lines = grammar.tokenizeLines '><'
      expect(lines[0][0]).toEqual value: '><', scopes: ['text.html.basic']

    it 'tokenizes < after tags without locking up', ->
      lines = grammar.tokenizeLines '<span><'
      expect(lines[0][3]).toEqual value: '<', scopes: ['text.html.basic']

  describe 'template script tags', ->
    it 'tokenizes the content inside the tag as HTML', ->
      lines = grammar.tokenizeLines '''
        <script id='id' type='text/template'>
          <div>test</div>
        </script>
      '''

      expect(lines[0][0]).toEqual value: '<', scopes: ['text.html.basic', 'punctuation.definition.tag.html']
      expect(lines[1][0]).toEqual value: '  ', scopes: ['text.html.basic', 'text.embedded.html']
      expect(lines[1][1]).toEqual value: '<', scopes: ['text.html.basic', 'text.embedded.html', 'meta.tag.block.any.html', 'punctuation.definition.tag.begin.html']

  describe 'CoffeeScript script tags', ->
    it 'tokenizes the content inside the tag as CoffeeScript', ->
      lines = grammar.tokenizeLines '''
        <script id='id' type='text/coffeescript'>
          -> console.log 'hi'
        </script>
      '''

      expect(lines[0][0]).toEqual value: '<', scopes: ['text.html.basic', 'punctuation.definition.tag.html']
      expect(lines[1][0]).toEqual value: '  ', scopes: ['text.html.basic', 'source.coffee.embedded.html']
      expect(lines[1][1]).toEqual value: '->', scopes: ['text.html.basic', 'source.coffee.embedded.html', 'storage.type.function.coffee']

  describe 'JavaScript script tags', ->
    beforeEach ->
      waitsForPromise -> atom.packages.activatePackage('language-javascript')

    it 'tokenizes the content inside the tag as JavaScript', ->
      lines = grammar.tokenizeLines '''
        <script id='id' type='text/javascript'>
          var hi = 'hi'
        </script>
      '''

      expect(lines[0][0]).toEqual value: '<', scopes: ['text.html.basic', 'punctuation.definition.tag.html']

      expect(lines[1][0]).toEqual value: '  ', scopes: ['text.html.basic', 'source.js.embedded.html']
      expect(lines[1][1]).toEqual value: 'var', scopes: ['text.html.basic', 'source.js.embedded.html', 'storage.modifier.js']

  describe "comments", ->
    it "tokenizes them", ->
      {tokens} = grammar.tokenizeLine '<!-- some comment --->'

      expect(tokens[0]).toEqual value: '<!--', scopes: ['text.html.basic', 'comment.block.html', 'punctuation.definition.comment.begin.html']
      expect(tokens[1]).toEqual value: ' some comment -', scopes: ['text.html.basic', 'comment.block.html']
      expect(tokens[2]).toEqual value: '-->', scopes: ['text.html.basic', 'comment.block.html', 'punctuation.definition.comment.end.html']

    it "tokenizes -- as an error", ->
      {tokens} = grammar.tokenizeLine '<!-- -- -->'

      expect(tokens[0]).toEqual value: '<!--', scopes: ['text.html.basic', 'comment.block.html', 'punctuation.definition.comment.begin.html']
      expect(tokens[1]).toEqual value: ' ', scopes: ['text.html.basic', 'comment.block.html']
      expect(tokens[2]).toEqual value: '--', scopes: ['text.html.basic', 'comment.block.html', 'invalid.illegal.bad-comments-or-CDATA.html']
      expect(tokens[3]).toEqual value: ' ', scopes: ['text.html.basic', 'comment.block.html']
      expect(tokens[4]).toEqual value: '-->', scopes: ['text.html.basic', 'comment.block.html', 'punctuation.definition.comment.end.html']

  describe "tags", ->
    it "tokenizes them", ->
      {tokens} = grammar.tokenizeLine '<randomtag attrib="yes">text</randomtag>'

      expect(tokens[0]).toEqual value: '<', scopes: ['text.html.basic', 'meta.tag.other.html', 'punctuation.definition.tag.begin.html']
      expect(tokens[1]).toEqual value: 'randomtag', scopes: ['text.html.basic', 'meta.tag.other.html', 'entity.name.tag.other.html']
      expect(tokens[3]).toEqual value: 'attrib', scopes: ['text.html.basic', 'meta.tag.other.html', 'entity.other.attribute-name.html']
      expect(tokens[5]).toEqual value: '"', scopes: ['text.html.basic', 'meta.tag.other.html', 'string.quoted.double.html', 'punctuation.definition.string.begin.html']
      expect(tokens[6]).toEqual value: 'yes', scopes: ['text.html.basic', 'meta.tag.other.html', 'string.quoted.double.html']
      expect(tokens[7]).toEqual value: '"', scopes: ['text.html.basic', 'meta.tag.other.html', 'string.quoted.double.html', 'punctuation.definition.string.end.html']
      expect(tokens[8]).toEqual value: '>', scopes: ['text.html.basic', 'meta.tag.other.html', 'punctuation.definition.tag.end.html']
      expect(tokens[9]).toEqual value: 'text', scopes: ['text.html.basic']
      expect(tokens[10]).toEqual value: '</', scopes: ['text.html.basic', 'meta.tag.other.html', 'punctuation.definition.tag.begin.html']
      expect(tokens[11]).toEqual value: 'randomtag', scopes: ['text.html.basic', 'meta.tag.other.html', 'entity.name.tag.other.html']
      expect(tokens[12]).toEqual value: '>', scopes: ['text.html.basic', 'meta.tag.other.html', 'punctuation.definition.tag.end.html']

    it "tokenizes out-of-order tags as invalid", ->
      {tokens} = grammar.tokenizeLine '<abc><def></abc></def>'

      expect(tokens[0]).toEqual value: '<', scopes: ['text.html.basic', 'meta.tag.other.html', 'punctuation.definition.tag.begin.html']
      expect(tokens[1]).toEqual value: 'abc', scopes: ['text.html.basic', 'meta.tag.other.html', 'entity.name.tag.other.html']
      expect(tokens[2]).toEqual value: '>', scopes: ['text.html.basic', 'meta.tag.other.html', 'punctuation.definition.tag.end.html']
      expect(tokens[3]).toEqual value: '<', scopes: ['text.html.basic', 'meta.tag.other.html', 'punctuation.definition.tag.begin.html']
      expect(tokens[4]).toEqual value: 'def', scopes: ['text.html.basic', 'meta.tag.other.html', 'entity.name.tag.other.html']
      expect(tokens[5]).toEqual value: '>', scopes: ['text.html.basic', 'meta.tag.other.html', 'punctuation.definition.tag.end.html']
      expect(tokens[6]).toEqual value: '</abc>', scopes: ['text.html.basic', 'invalid.illegal.out-of-order-tag.html']
      expect(tokens[7]).toEqual value: '</', scopes: ['text.html.basic', 'meta.tag.other.html', 'punctuation.definition.tag.begin.html']
      expect(tokens[8]).toEqual value: 'def', scopes: ['text.html.basic', 'meta.tag.other.html', 'entity.name.tag.other.html']
      expect(tokens[9]).toEqual value: '>', scopes: ['text.html.basic', 'meta.tag.other.html', 'punctuation.definition.tag.end.html']

    it "tokenizes singleton tags", ->
      {tokens} = grammar.tokenizeLine '<area><hr/>'

      expect(tokens[0]).toEqual value: '<', scopes: ['text.html.basic', 'meta.tag.singleton.any.html', 'punctuation.definition.tag.begin.html']
      expect(tokens[1]).toEqual value: 'area', scopes: ['text.html.basic', 'meta.tag.singleton.any.html', 'entity.name.tag.singleton.any.html']
      expect(tokens[2]).toEqual value: '>', scopes: ['text.html.basic', 'meta.tag.singleton.any.html', 'punctuation.definition.tag.end.html']
      expect(tokens[3]).toEqual value: '<', scopes: ['text.html.basic', 'meta.tag.singleton.any.html', 'punctuation.definition.tag.begin.html']
      expect(tokens[4]).toEqual value: 'hr', scopes: ['text.html.basic', 'meta.tag.singleton.any.html', 'entity.name.tag.singleton.any.html']
      expect(tokens[5]).toEqual value: '/>', scopes: ['text.html.basic', 'meta.tag.singleton.any.html', 'punctuation.definition.tag.end.html']

    it "tokenizes singleton tags as well as tags that don't require a closing tag without marking any following tags as out-of-order", ->
      {tokens} = grammar.tokenizeLine '<br><b><p></b>'

      expect(tokens[0]).toEqual value: '<', scopes: ['text.html.basic', 'meta.tag.singleton.any.html', 'punctuation.definition.tag.begin.html']
      expect(tokens[1]).toEqual value: 'br', scopes: ['text.html.basic', 'meta.tag.singleton.any.html', 'entity.name.tag.singleton.any.html']
      expect(tokens[2]).toEqual value: '>', scopes: ['text.html.basic', 'meta.tag.singleton.any.html', 'punctuation.definition.tag.end.html']
      expect(tokens[3]).toEqual value: '<', scopes: ['text.html.basic', 'meta.tag.inline.any.html', 'punctuation.definition.tag.begin.html']
      expect(tokens[4]).toEqual value: 'b', scopes: ['text.html.basic', 'meta.tag.inline.any.html', 'entity.name.tag.inline.any.html']
      expect(tokens[5]).toEqual value: '>', scopes: ['text.html.basic', 'meta.tag.inline.any.html', 'punctuation.definition.tag.end.html']
      expect(tokens[6]).toEqual value: '<', scopes: ['text.html.basic', 'meta.tag.block.any.html', 'punctuation.definition.tag.begin.html']
      expect(tokens[7]).toEqual value: 'p', scopes: ['text.html.basic', 'meta.tag.block.any.html', 'entity.name.tag.block.any.html']
      expect(tokens[8]).toEqual value: '>', scopes: ['text.html.basic', 'meta.tag.block.any.html', 'punctuation.definition.tag.end.html']
      expect(tokens[9]).toEqual value: '</', scopes: ['text.html.basic', 'meta.tag.inline.any.html', 'punctuation.definition.tag.begin.html']
      expect(tokens[10]).toEqual value: 'b', scopes: ['text.html.basic', 'meta.tag.inline.any.html', 'entity.name.tag.inline.any.html']
      expect(tokens[11]).toEqual value: '>', scopes: ['text.html.basic', 'meta.tag.inline.any.html', 'punctuation.definition.tag.end.html']