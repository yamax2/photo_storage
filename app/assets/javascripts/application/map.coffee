$(document)
  .on 'turbolinks:load', ->
    $map = $('.page-map-content')

    return unless $map.length > 0

    $.get $map.data('url'), (response) ->
      return unless response.length > 0

      $map.show()
      map = L.map('map').setView($map.data('center'), 13)

      L.tileLayer($map.data('tile_layer'), {attribution: $map.data('attribution')}).addTo(map)
      control = L.control.layers(null, null).addTo(map)

      for track in response
        new L.GPX(
          track.url,
          async: true,
          marker_options:
            clickable: true
            startIconUrl: 'http://github.com/mpetazzoni/leaflet-gpx/raw/master/pin-icon-start.png',
            endIconUrl: 'http://github.com/mpetazzoni/leaflet-gpx/raw/master/pin-icon-end.png',
            shadowUrl: 'http://github.com/mpetazzoni/leaflet-gpx/raw/master/pin-shadow.png'
        ).on('loaded', ((e) ->
            gpx = e.target
            control.addOverlay(gpx, "#{this.name}: #{this.avg_speed}, #{this.distance}, #{this.duration}")
          ).bind(track)
        ).addTo(map)
