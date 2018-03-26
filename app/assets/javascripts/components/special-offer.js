$.onmount('[data-toggle=special-offer]', function () {
  var $el = $(this)

  var onLoad = function (query, callback) {
    $.ajax({
      url: '/special_offer/search',
      data: {
        q: query
      },
      success: function (resp) {
        callback(resp.products)
      },
      error: callback
    })
  }

  $el.selectize({
    load: onLoad,
    preload: 'focus',
    valueField: 'id',
    labelField: 'title',
    options: [],
    placeholder: 'Search product here..',
    searchField: ['id', 'title']
  })

  var object = $el.data('product')

  if (object) {
    $el[0].selectize.addOption(object)
    $el[0].selectize.setValue(object.id)
  }
})
