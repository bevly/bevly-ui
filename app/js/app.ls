angular.module("DrinkMenu", ['ngRoute'])
  .service 'UrlSort', ['$location', ($location) ->
    sortId: ->
      ($location.path() || 'name').replace(/^\//, '')
  ]

  .service 'Drink', ->
    rating: (drink) ->
      if drink.ratingScore? && drink.ratingScore > 0
        drink.ratingScore
      else null

    ratingDescription: (drink) ->
      rating = @rating(drink)
      if rating then "BA: #{rating}" else ''

    abvDescription: (drink) -> "#{drink.abv}%"
  
  .controller "DrinkController", ['$scope', '$http', '$location', 'Drink',
    'UrlSort',
    ($scope, $http, $location, Drink, UrlSort) !->
      $scope.Drink = Drink
      
      $scope.drinks = []

      $http.get('/api/frisco/drink/')
        .success (data) ->
          $scope.drinks = data.drinks

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

      applySort = -> $scope.sort(UrlSort.sortId())
      $scope.$watch(UrlSort~sortId, applySort)
  ]
