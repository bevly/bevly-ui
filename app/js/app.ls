require '../bev-select/bevSelect'

angular.module("DrinkMenu", ['BevSelect'])
  .factory 'Url', ['$location', ($location) ->
    normalizedPath: ->
      ($location.path() || '').replace(/^\//, '')
    sortId: ->
      @normalizedPath().split(':')[1] || 'name'
    sourceId: ->
      @normalizedPath().split(':')[0]
  ]

  .factory 'DrinkApi', ['$http', ($http) ->
    getDrinks: (source) -> $http.get("/api/bevly/#{source.id}/drink/")
  ]

  .factory 'Drink', ->
    setSource: (source) -> @source = source

    servingSize: (drink) -> drink["#{@source}ServingSize"]

    rating: (drink) ->
      if drink.ratingScore? && drink.ratingScore > 0
        drink.ratingScore
      else null

    ratingDescription: (drink) ->
      rating = @rating(drink)
      if rating then "BA: #{rating}" else ''

    abvDescription: (drink) ->
      if drink.abv > 0 then "#{drink.abv}% ABV" else ''

    description: (drink) ->
      drink["#{@source}Description"] || drink.description
  
  .controller "DrinkController", ['$scope', '$location', 'Drink',
    'Url', 'DrinkApi',
    ($scope, $location, Drink, Url, DrinkApi) !->
      $scope.Drink = Drink
      
      $scope.drinks = []
      $scope.availableSources =
        * name: 'Frisco', id: \frisco
        * name: 'Ale House', id: \ale_house
      $scope.selectedSource = $scope.availableSources[0]

      loadDrinks = ->
        window.pscope = $scope
        $scope.loadingDrinks = true
        console.log("Loading drinks for #{$scope.selectedSource.id}")
        Drink.setSource($scope.selectedSource.id)
        DrinkApi.getDrinks($scope.selectedSource)
          .success (data) ->
            $scope.drinks = data.drinks
            delete $scope.loadingDrinks

      $scope.changeSource = ->
        window.location.hash = "#{$scope.selectedSource.id}:#{Url.sortId()}"
        
      $scope.sortSelected = (key) -> key == $scope.ordering.id

      subsortByName = (key, reverse) ->
        [key, if reverse then '-name' else 'name']

      $scope.sort = (id) ->
        sort = $scope.sortMap[id] || $scope.sortMap.name
        ordering = ^^sort
        if ordering.id != 'name'
          ordering.key = subsortByName(ordering.key)
        $scope.ordering = ordering

      sorter = (key, fn) ->
        fn.key = key
        $scope.sort[key] = fn

      sorter \abv, -> it.abv || 100
      sorter \rating, -> Drink.rating(it) || 0

      $scope.sorters =
        * id: 'name', title: 'Name', key: 'name'
        * id: 'rating', title: 'Rating', key: $scope.sort.rating, reverse: true
        * id: 'abv', title: 'ABV', key: $scope.sort.abv

      $scope.sortMap = { }
      for sort in $scope.sorters
        $scope.sortMap[sort.id] = sort

      applySort = -> $scope.sort(Url.sortId())
      applySource = ->
        selectSourceWithId(Url.sourceId())
        loadDrinks()

      selectSourceWithId = (id) ->
        id ?= $scope.availableSources[0]?.id
        return unless id
        for source in $scope.availableSources
          if source.id == id
            $scope.selectedSource = source
            break
        
      $scope.$watch(Url~sortId, applySort)
      $scope.$watch(Url~sourceId, applySource)
  ]
