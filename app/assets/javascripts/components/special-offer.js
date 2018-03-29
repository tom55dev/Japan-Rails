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

  var renderItem = function (item, escape) {
    return '<div>' +
      '<img src="' + item.featured_image_url + '" width="50px"/>&nbsp;&nbsp;&nbsp;' +
      item.title +
    '</div>'
  }

  $el.selectize({
    load: onLoad,
    preload: 'focus',
    valueField: 'id',
    labelField: 'title',
    options: [],
    placeholder: 'Search product here..',
    searchField: ['id', 'title'],
    render: {
      option: renderItem,
      item: renderItem
    }
  })

  var object = $el.data('product')

  if (object) {
    $el[0].selectize.addOption(object)
    $el[0].selectize.setValue(object.id)
  }
})
