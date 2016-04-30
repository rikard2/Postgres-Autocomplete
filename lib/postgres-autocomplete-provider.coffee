{CompositeDisposable} = require 'atom'

module.exports =
class AutocompleteProvider

  schema: {}

  constructor: (schema) ->
    @schema = schema

  selector: '.sql'
  inclusionPriority: 1
  excludeLowerPriority: true

  scopeText: (before, after) ->
    reBefore = [ /^/, /;/ ]
    reAfter = [ /$/, /;/ ]
    min = -1
    max = -1
    for re in reBefore
      if match = before.match(re)
        min = match.index if match.index > min || min == -1

    for re in reAfter
      if match = after.match(re)
        max = match.index if match.index < max || max == -1

    max = after.length if max == -1
    min = before.length if min == -1

    before = before.substr(min, before.length - min)
    after = after.substr(0, max)

    return before + after

  findJoins: (scopeText) ->
    joins = []
    re = /(?:from|join)\s+([A-Za-z]+)((?:\s+)(?!on|using)[A-Za-z]+)?/gmi

    while lastWords = re.exec scopeText
      t = { 'table': lastWords[1], 'alias': lastWords[2] }
      t.alias = t.alias.trim() if t.alias

      joins.push(t)

    return joins

  getSuggestionsFromJoins: (beforeDot, afterDot, joins) ->

    suggestions = []
    tables = []

    for j in joins
      if beforeDot == j.alias || beforeDot == j.table
        tables.push(j.table)

    console.log 'getSuggestionsFromJoins', tables, @schema.tables
    for t in tables
      for st in @schema.tables
        if st.table == t
          for c in st.columns
            if !afterDot || c.column.indexOf(afterDot) >= 0
              suggestions.push(@suggestColumn(c))

    return suggestions

  suggestTables: (prefix) ->
    suggestions = []

    for t in @schema.tables
      if !prefix || t.table.indexOf(prefix) >= 0
        suggestions.push({
          text: t.table,
          type: 'type' # (optional)
          rightLabel: 'table' # (optional)
          description: 'Whatevs'
        })

    return suggestions
  suggestColumn: (column) ->
    suggestions = []

    suggestion =
      text: column.column,
      type: 'variable' # (optional)
      rightLabel: column.datatype # (optional)
      description: 'Whatevs'

    return suggestion

  beforePrefix: (beforeOnSameRow, re) ->
    match = beforeOnSameRow.match(re)
    if !match
      return null

    if match.length > 1
      alias = match[1]
      return alias

    return null

  wordBefore: (beforeOnSameRow) ->



  getSuggestions: (options) ->
    console.log 'prefix', options
    completions = []
    chain = options.scopeDescriptor.getScopeChain()
    x = options.scopeDescriptor.getScopesArray()

    before = options.editor.getTextInBufferRange([[0, 0], options.bufferPosition]);
    beforeOnSameRow = options.editor.getTextInBufferRange([[0, options.bufferPosition.row], options.bufferPosition]);
    after = options.editor.getTextInBufferRange([options.bufferPosition, [999, 999]]);

    scopetext = @scopeText(before, after)
    joins = @findJoins(scopetext)
    beforeDot = @beforePrefix(before, /([A-Za-z]+)\.(?:[A-Za-z]+)?$/i)
    afterDot = @beforePrefix(before, /(?:[A-Za-z]+)\.([A-Za-z]+)$/i)
    beforeWhitespace = @beforePrefix(before, /(?:^|\s*)([A-Za-z]+)\s+$/mi)
    afterWhitespace = @beforePrefix(before, /\s+([A-Za-z]+)$/mi)
    # console.log 'beforeDot', beforeDot, 'beforeWhitespace', beforeWhitespace, 'afterDot', afterDot, 'afterWhitespace', afterWhitespace, '=>', beforeOnSameRow

    if afterWhitespace && afterWhitespace.match(/from|join/i)
      for t in @suggestTables(options.prefix)
        completions.push(t)

    if options.activatedManually == true && beforeWhitespace && beforeWhitespace.match(/from|join/i)
      for t in @suggestTables()
        completions.push(t)

    if (beforeDot || afterDot) && beforeDot != null
      suggestions = @getSuggestionsFromJoins(beforeDot, afterDot, joins)

      for s in suggestions
        completions.push(s)

    return completions

  onDidInsertSuggestion: ({editor, triggerPosition, suggestion}) ->
    console.log 'onDidInsertSuggestion'
