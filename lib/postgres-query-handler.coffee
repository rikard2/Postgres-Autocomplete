pg = require 'pg'

module.exports =
class PostgresQueryHandler
  constructor: ->

  query: (query) ->
    promise = new Promise (resolve, error) ->
      constring = 'postgres://localhost/rikard'

      pg.connect(constring, (err, client) ->
        if err
          console.error 'pg connect error', err

          error(err)

        p = new PostgresQueryHandler()


        p.getResults(client, query, resolve, error)

      )

    return promise

  getResults: (client, query, resolve, error) ->

    client.query({ text: query, rowMode: 'array', multiResult: true }, (err, result) ->
      if err
        console.error 'pg query error', err
        error(err)

      resolve(result)
    )
