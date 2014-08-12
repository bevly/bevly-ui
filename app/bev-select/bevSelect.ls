angular.module("BevSelect", [])
  .directive "bevSelect", ->
    restrict: 'E'
    scope:
      change: '&onchange'
      options: '=options'
      model: '=model'
      display: '=display'
      id: '=id'
    templateUrl: 'bev-select/t_bevselect.html'
    
    controller: ($scope, $timeout) ->
      $scope.itemText = (item) -> item[$scope.display ? 'name']
      $scope.itemId = (item) -> item[$scope.id ? 'id']
      $scope.itemSelected = (item) -> @itemId(item) == @itemId(@model)
      $scope.selectItem = (item) ->
        if $scope.itemId(item) != $scope.itemId($scope.model)
          $scope.model = item
          console.log("New item: #{$scope.itemId(item)}")
          $timeout((-> $scope.change(item)), 0)
      
    link: (scope, element, attrs) ->
      scope.prefix = attrs.prefix
      scope.model ?= scope.options[0]

      scope.hidden = true

      combo = -> element.find('.bev-select-items')
      comboDropFocus = (e) ->
        e.preventDefault()
        hideCombo()

      scope.$on '$destroy', hideCombo

      showCombo = ->
        return unless scope.hidden
        selSpan = element.find('.selected-display')
        pos = selSpan.position()
        c = combo()
        jQuery(document.body).on 'click', comboDropFocus
        c.on 'click', (e) ->
          e.preventDefault()
        c.css do
          left: "#{Math.floor(pos.left)}px"
          top: "#{Math.floor(pos.top + selSpan.height())}px"
        c.show()
        scope.hidden = false

      hideCombo = ->
        return if scope.hidden
        jQuery(document.body).off 'click', comboDropFocus
        combo().hide()
        scope.hidden = true
            
      element.on 'click', ->
        if scope.hidden
          showCombo()
        else
          hideCombo()
          