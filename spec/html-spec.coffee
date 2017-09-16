path = require 'path'
grammarTest = require 'atom-grammar-test'

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

  describe 'script tags', ->
    it 'tokenizes the tag attributes', ->
      tokens = grammar.tokenizeLines '''
        <script id="id" type="text/html">
        </script>
      '''

      expect(tokens[0][0]).toEqual value: '<', scopes: ['text.html.basic', 'punctuation.definition.tag.html']
      expect(tokens[0][1]).toEqual value: 'script', scopes: ['text.html.basic', 'entity.name.tag.script.html']
      expect(tokens[0][3]).toEqual value: 'id', scopes: ['text.html.basic', 'meta.attribute-with-value.id.html', 'entity.other.attribute-name.id.html']
      expect(tokens[0][4]).toEqual value: '=', scopes: ['text.html.basic', 'meta.attribute-with-value.id.html', 'punctuation.separator.key-value.html']
      expect(tokens[0][5]).toEqual value: '"', scopes: ['text.html.basic', 'meta.attribute-with-value.id.html', 'string.quoted.double.html', 'punctuation.definition.string.begin.html']
      expect(tokens[0][6]).toEqual value: 'id', scopes: ['text.html.basic', 'meta.attribute-with-value.id.html', 'string.quoted.double.html', 'meta.toc-list.id.html']
      expect(tokens[0][7]).toEqual value: '"', scopes: ['text.html.basic', 'meta.attribute-with-value.id.html', 'string.quoted.double.html', 'punctuation.definition.string.end.html']
      expect(tokens[0][9]).toEqual value: 'type', scopes: ['text.html.basic', 'entity.other.attribute-name.html']
      expect(tokens[0][10]).toEqual value: '=', scopes: ['text.html.basic']
      expect(tokens[0][11]).toEqual value: '"', scopes: ['text.html.basic', 'string.quoted.double.html', 'punctuation.definition.string.begin.html']
      expect(tokens[0][12]).toEqual value: 'text/html', scopes: ['text.html.basic', 'string.quoted.double.html']
      expect(tokens[0][13]).toEqual value: '"', scopes: ['text.html.basic', 'string.quoted.double.html', 'punctuation.definition.string.end.html']
      expect(tokens[0][14]).toEqual value: '>', scopes: ['text.html.basic', 'punctuation.definition.tag.html']
      expect(tokens[1][0]).toEqual value: '</', scopes: ['text.html.basic', 'punctuation.definition.tag.html']
      expect(tokens[1][1]).toEqual value: 'script', scopes: ['text.html.basic', 'entity.name.tag.script.html']
      expect(tokens[1][2]).toEqual value: '>', scopes: ['text.html.basic', 'punctuation.definition.tag.html']

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
      expect(lines[1][1]).toEqual value: 'var', scopes: ['text.html.basic', 'source.js.embedded.html', 'storage.type.var.js']

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

  grammarTest path.join(__dirname, 'fixtures/syntax_test_html.html')
  grammarTest path.join(__dirname, 'fixtures/syntax_test_html_template_fragments.html')

  describe "entities", ->
    it "tokenizes & and characters after it", ->
      {tokens} = grammar.tokenizeLine '& &amp; &a'

      expect(tokens[0]).toEqual value: '&', scopes: ['text.html.basic', 'invalid.illegal.bad-ampersand.html']
      expect(tokens[3]).toEqual value: 'amp', scopes: ['text.html.basic', 'constant.character.entity.html', 'entity.name.entity.other.html']
      expect(tokens[4]).toEqual value: ';', scopes: ['text.html.basic', 'constant.character.entity.html', 'punctuation.definition.entity.end.html']
      expect(tokens[7]).toEqual value: 'a', scopes: ['text.html.basic', 'constant.character.entity.html', 'entity.name.entity.other.html']
