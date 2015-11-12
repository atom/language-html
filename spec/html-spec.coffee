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

  describe "attributes", ->
    it "tokenizes them", ->
      {tokens} = grammar.tokenizeLine '<randomtag q="hello" b=true id="no"></randomtag>'

      expect(tokens[2]).toEqual value: ' ', scopes: ['text.html.basic', 'meta.tag.any.html']
      expect(tokens[3]).toEqual value: 'q', scopes: ['text.html.basic', 'meta.tag.any.html', 'meta.attribute-with-value.html', 'entity.other.attribute-name.html']
      expect(tokens[4]).toEqual value: '=', scopes: ['text.html.basic', 'meta.tag.any.html', 'meta.attribute-with-value.html', 'punctuation.separator.key-value.html']
      expect(tokens[5]).toEqual value: '"', scopes: ['text.html.basic', 'meta.tag.any.html', 'meta.attribute-with-value.html', 'string.quoted.double.html', 'punctuation.definition.string.begin.html']
      expect(tokens[6]).toEqual value: 'hello', scopes: ['text.html.basic', 'meta.tag.any.html', 'meta.attribute-with-value.html', 'string.quoted.double.html']
      expect(tokens[7]).toEqual value: '"', scopes: ['text.html.basic', 'meta.tag.any.html', 'meta.attribute-with-value.html', 'string.quoted.double.html', 'punctuation.definition.string.end.html']
      expect(tokens[9]).toEqual value: 'b', scopes: ['text.html.basic', 'meta.tag.any.html', 'meta.attribute-with-value.html', 'entity.other.attribute-name.html']
      expect(tokens[10]).toEqual value: '=', scopes: ['text.html.basic', 'meta.tag.any.html', 'meta.attribute-with-value.html', 'punctuation.separator.key-value.html']
      expect(tokens[11]).toEqual value: 'true', scopes: ['text.html.basic', 'meta.tag.any.html', 'meta.attribute-with-value.html', 'string.unquoted.html']
      expect(tokens[13]).toEqual value: 'id', scopes: ['text.html.basic', 'meta.tag.any.html', 'meta.attribute-with-value.id.html', 'entity.other.attribute-name.id.html']
      expect(tokens[14]).toEqual value: '=', scopes: ['text.html.basic', 'meta.tag.any.html', 'meta.attribute-with-value.id.html', 'punctuation.separator.key-value.html']
      expect(tokens[15]).toEqual value: '"', scopes: ['text.html.basic', 'meta.tag.any.html', 'meta.attribute-with-value.id.html', 'string.quoted.double.html', 'punctuation.definition.string.begin.html']
      expect(tokens[16]).toEqual value: 'no', scopes: ['text.html.basic', 'meta.tag.any.html', 'meta.attribute-with-value.id.html', 'string.quoted.double.html', 'meta.toc-list.id.html']
      expect(tokens[17]).toEqual value: '"', scopes: ['text.html.basic', 'meta.tag.any.html', 'meta.attribute-with-value.id.html', 'string.quoted.double.html', 'punctuation.definition.string.end.html']
      expect(tokens[18]).toEqual value: '>', scopes: ['text.html.basic', 'meta.tag.any.html', 'punctuation.definition.tag.html']

  describe "comments", ->
    it "tokenizes -- as an error", ->
      {tokens} = grammar.tokenizeLine '<!-- some comment --->'

      expect(tokens[0]).toEqual value: '<!--', scopes: ['text.html.basic', 'comment.block.html', 'punctuation.definition.comment.html']
      expect(tokens[1]).toEqual value: ' some comment -', scopes: ['text.html.basic', 'comment.block.html']
      expect(tokens[2]).toEqual value: '-->', scopes: ['text.html.basic', 'comment.block.html', 'punctuation.definition.comment.html']

      {tokens} = grammar.tokenizeLine '<!-- -- -->'

      expect(tokens[0]).toEqual value: '<!--', scopes: ['text.html.basic', 'comment.block.html', 'punctuation.definition.comment.html']
      expect(tokens[1]).toEqual value: ' ', scopes: ['text.html.basic', 'comment.block.html']
      expect(tokens[2]).toEqual value: '--', scopes: ['text.html.basic', 'comment.block.html', 'invalid.illegal.bad-comments-or-CDATA.html']
      expect(tokens[3]).toEqual value: ' ', scopes: ['text.html.basic', 'comment.block.html']
      expect(tokens[4]).toEqual value: '-->', scopes: ['text.html.basic', 'comment.block.html', 'punctuation.definition.comment.html']
