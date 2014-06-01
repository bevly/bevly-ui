angular.module("DrinkMenu", [])
  .service 'Drink', ->
    rating: (drink) ->
      if it.ratingScore? && it.ratingScore > 0
        it.ratingScore
      else null
        
    ratingDescription: (drink) ->
      rating = @rating(drink)
      if rating then "BA: #{rating}" else ''

    abvDescription: (drink) -> "#{drink.abv}%"
  
  .controller "Drinks", ['$scope', '$http', 'Drink',
    ($scope, $http, Drink) !->
      $scope.Drink = Drink
      
      $scope.drinks = []

      $http.get('/api/frisco/drink/')
        .success (data) ->
          window.data = data
          console.log("Fetched data: " + data)
          $scope.drinks = data.drinks

      $scope.orderKey = ->
        key = $scope.ordering.key
        if angular.isArray(key) then key[0] else key

      $scope.selectedCls = (key) ->
        if key == $scope.orderKey() then 'selected' else ''

      subsortByName = (key, reverse) ->
        [key, if reverse then '-name' else 'name']

      $scope.sort = (key, reverse=false) ->
        name = if typeof(key) == 'function' then key.name else key
        if key != 'name'
          key = subsortByName(key, reverse)
        $scope.ordering = (key: key, reverse: reverse)

      sorter = (key, fn) ->
        fn.key = key
        $scope.sort[key] = fn

      sorter \abv, -> it.abv || 100
      sorter \rating, -> Drink.rating(it) || 0

      $scope.sorters =
        * title: 'Name', key: 'name'
        * title: 'Rating', key: $scope.sort.rating, reverse: true
        * title: 'ABV', key: $scope.sort.abv

      $scope.sort('name')
  ]
