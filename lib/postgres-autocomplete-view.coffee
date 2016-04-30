module.exports =
class PostgresAutocompleteView
  constructor: (serializedState) ->
    # Create root element
    @element = document.createElement('div')
    @element.classList.add('postgres-autocomplete')

    # Create message element
    message = document.createElement('div')
    message.textContent = "The PostgresAutocomplete package is Alive! It's ALIVE!"
    message.classList.add('message')
    @element.appendChild(message)

  # Returns an object that can be retrieved when package is activated
  serialize: ->

  # Tear down any state and detach
  destroy: ->
    @element.remove()

  getElement: ->
    @element

  getResultsElement: (results, error) ->
    message = document.createElement('div')
    message.textContent = "The PostgresHelperCoffee package is Alive! It's ALIVE!"
    message.classList.add('message')
    @element.appendChild(message)

    #@resultsBox.style.display = 'block'
    #@errorElement.style.display = 'none'

    if @resultsBox
      @resultsBox.childNodes.length = 0
    else
      @resultsBox = document.createElement('div')



    @resultsBox.classList.add('postgres-helper-coffee-results')
    @resultsBox.textContent = ""

    if error
      if @errorElement
        @errorElement.childNodes.length = 0
      else
        @errorElement = document.createElement('div')

      #@errorElement.style.display = 'block'
      #@resultsElement.style.display = 'none'

      @errorElement.classList.add('postgres-helper-coffee-error')
      @errorElement.textContent = error

      return @errorElement

    table = document.createElement('table')
    table.classList.add('table')

    tr = document.createElement('tr')
    for f in results.fields
      th = document.createElement('th')
      th.textContent = f
      tr.appendChild(th)
      table.appendChild(tr)

    for row in results.rows
      tr = document.createElement('tr')

      for c in row
        td = document.createElement('td')
        td.textContent = c
        tr.appendChild(td)

      table.appendChild(tr)

    @resultsBox.appendChild(table)

    return @resultsBox
