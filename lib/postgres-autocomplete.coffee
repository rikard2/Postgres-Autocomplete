PostgresAutocompleteView = require './postgres-autocomplete-view'
{CompositeDisposable} = require 'atom'
PostgresQueryHandler = require('./postgres-query-handler.coffee')

module.exports = PostgresAutocomplete =
  postgresAutocompleteView: null
  modalPanel: null
  subscriptions: null
  provider: null
  schema: { tables: [] }

  loadSchema: ->
    slf = @
    loadPromise = new Promise (resolve) ->
      p = new PostgresQueryHandler()

      query = 'SELECT table_schema, table_name, table_type
      FROM information_schema.tables
      WHERE substr(table_schema, 1, 3) != \'pg_\' and table_schema != \'information_schema\'
      order by table_schema, table_type, table_name;'
      promise = p.query(query)
      promise.then (result) =>
        console.log 'then', result
        slf.schema.tables = ({ 'schema': t[0], 'table': t[1], 'columns': [] } for t in result[0].rows)

        columnQuery = 'select c.table_name, c.column_name, c.data_type, c.is_nullable,
          c.ordinal_position from information_schema.columns c
          where substr(table_schema, 1, 3) != \'pg_\' and table_schema != \'information_schema\';'

        p.query(columnQuery).then (result) =>
          #@columns = ({ 'schema': t[0], 'table': t[1] } for t in result[0].rows)
          for c in result[0].rows
            for t in slf.schema.tables
              if t.table == c[0]
                t.columns.push({ 'column': c[1], 'datatype': c[2] })

          resolve(slf.schema)

    return loadPromise

  executeQuery: () ->
    selectedText = atom.workspace.getActiveTextEditor().getSelectedText()

    p = new PostgresQueryHandler()

    promise = p.query(selectedText)

    promise.then (results) =>
      console.log 'result', results
      fields = []
      rows = []
      for result in results
        for f in result.fields
          fields.push(f.name)

        for r in result.rows
          z = []
          for x in r
            z.push(x)

          rows.push(z)

      console.log 'XXX', fields, rows

      resultsElement = @postgresAutocompleteView.getResultsElement({
        fields: fields,
        rows: rows
        })

      atom.workspace.addBottomPanel(item: resultsElement, visible: true)
    , (err) =>
      resultsElement = @postgresAutocompleteView.getResultsElement(null, err)

      atom.workspace.addBottomPanel(item: resultsElement, visible: true)

  activate: (state) ->
    @postgresAutocompleteView = new PostgresAutocompleteView(state.postgresAutocompleteViewState)
    @modalPanel = atom.workspace.addModalPanel(item: @postgresAutocompleteView.getElement(), visible: false)

    unless @provider?
      AutocompleteProvider = require('./postgres-autocomplete-provider')
      @provider = new AutocompleteProvider()

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable
    slf = @
    @loadSchema().then (schema) ->
      slf.provider.schema = schema
      console.log 'schema loaded.'

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'postgres-autocomplete:toggle': => @toggle()
    @subscriptions.add atom.commands.add 'atom-workspace', 'postgres-autocomplete:execute': => @executeQuery()

  deactivate: ->
    @modalPanel.destroy()
    @subscriptions.dispose()
    @postgresAutocompleteView.destroy()

  provide: ->
    @provider

  serialize: ->
    postgresAutocompleteViewState: @postgresAutocompleteView.serialize()

  toggle: ->
    console.log 'PostgresAutocomplete was toggled!'

    if @modalPanel.isVisible()
      @modalPanel.hide()
    else
      @modalPanel.hide()
