searchLimitIncreasing = false

Deps.autorun ->
  # Every time search query is changed, we reset counts
  # (We don't want to reset counts on currentSearchLimit change)
  Session.get 'currentSearchQuery'
  Session.set 'currentSearchQueryCountPublications', 0
  Session.set 'currentSearchQueryCountPeople', 0

  searchLimitIncreasing = false

Deps.autorun ->
  Session.set 'currentSearchQueryReady', false
  if Session.get('currentSearchLimit') and Session.get('currentSearchQuery')
    Meteor.subscribe 'search-results', Session.get('currentSearchQuery'), Session.get('currentSearchLimit'), ->
      Session.set 'currentSearchQueryReady', true

Deps.autorun ->
  if Session.get 'indexActive'
    Meteor.subscribe 'search-available'

Template.results.rendered = ->
  $(@findAll '.chzn').chosen()

  $(@findAll '.scrubber').iscrubber()

  $(@findAll '#score-range').slider
    range: true
    min: 0
    max: 100
    values: [0, 100]
    step: 10
    slide: (event, ui) ->
      $(@findAll '#score').val(ui.values[ 0 ] + ' - ' + ui.values[ 1 ])

  $(@findAll '#score').val($(@findAll '#score-range').slider('values', 0) + ' - ' + $(@findAll '#score-range').slider('values', 1))

  $(@findAll '#date-range').slider
    range: true
    min: 0
    max: 100
    values: [0, 100]
    step: 10
    slide: (event, ui) ->
      $(@findAll '#pub-date').val(ui.values[0] + ' - ' + ui.values[1])

  $(@findAll '#pub-date').val($(@findAll '#date-range').slider('values', 0) + ' - ' + $(@findAll '#date-range').slider('values', 1))

  if Session.get 'currentSearchQueryReady'
    searchLimitIncreasing = false

Template.results.created = ->
  $(window).on 'scroll.results', ->
    if $(document).height() - $(window).scrollTop() <= 2 * $(window).height()
      increaseSearchLimit 10

Template.results.destroyed = ->
  $(window).off 'scroll.results'

increaseSearchLimit = (pageSize) ->
  if not searchLimitIncreasing
    searchLimitIncreasing = true
    Session.set 'currentSearchLimit', (Session.get('currentSearchLimit') or 0) + pageSize

Template.results.publications = ->
  if not Session.get('currentSearchLimit') or not Session.get('currentSearchQuery')
    return

  searchResult = SearchResults.findOne
    query: Session.get 'currentSearchQuery'

  if not searchResult
    return

  Session.set 'currentSearchQueryCountPublications', searchResult.countPublications
  Session.set 'currentSearchQueryCountPeople', searchResult.countPeople

  Publications.find
    'searchResult.id': searchResult._id
  ,
    sort: [
      ['searchResult.order', 'asc']
    ]
    limit: Session.get 'currentSearchLimit'

Template.resultsCount.publications = ->
  Session.get 'currentSearchQueryCountPublications'

Template.resultsCount.people = ->
  Session.get 'currentSearchQueryCountPeople'

Template.noResults.noResults = ->
  Session.get('currentSearchQueryReady') and not Session.get('currentSearchQueryCountPublications') and not Session.get('currentSearchQueryCountPeople')

Template.resultsSearchInvitation.searchInvitation = ->
  not Session.get('currentSearchQuery')

Template.publicationSearchResult.displayDay = (time) ->
  moment(time).format 'MMMM Do YYYY'

Template.publicationSearchResult.events =
  'click .preview-link': (e, template) ->
    e.preventDefault()
    Meteor.subscribe 'publications-by-id', @_id, ->
      Deps.afterFlush ->
        $(template.findAll '.abstract').slideToggle(200)

Template.sidebarSearch.events =
  'blur #title': (e, template) ->
    Session.set 'currentSearchQuery', $(template.findAll '#title').val()

  'change #title': (e, template) ->
    Session.set 'currentSearchQuery', $(template.findAll '#title').val()

  'keyup #title': (e, template) ->
    Session.set 'currentSearchQuery', $(template.findAll '#title').val()
