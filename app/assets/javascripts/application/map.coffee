$(document)
  .on 'turbolinks:load', ->
    $map = $('.page-map-content')

    return unless $map.length > 0

    $.get $map.data('url'), (response) ->
      return unless response.length > 0

      $map.show()
      map = L.map('map').setView($map.data('center'), 13)

      L.tileLayer($map.data('tile_layer'), {attribution: $map.data('attribution')}).addTo(map)

      # p1 = L.latLng(59.27630833333333, 60.104775000000004)
      # p2 = L.latLng(56.68363055555556, 54.33260277777778)
      # bounds = L.latLngBounds(p1, p2)
      # map.fitBounds(bounds)

      tracks = {}

      for track in response
        new L.GPX(
          track.url,
          async: true,
          marker_options:
            clickable: true
            startIconUrl: 'https://raw.githubusercontent.com/mpetazzoni/leaflet-gpx/master/pin-icon-start.png',
            endIconUrl: 'https://raw.githubusercontent.com/mpetazzoni/leaflet-gpx/master/pin-icon-end.png',
            shadowUrl: 'https://raw.githubusercontent.com/mpetazzoni/leaflet-gpx/master/pin-shadow.png'
          polyline_options:
            color: track.color
        ).on('loaded', ((e) ->
            tracks[this.id] = e.target

            if Object.keys(tracks).length == response.length
              control = L.control.layers(null, null).addTo(map)
              for value in response
                gpx = tracks[value.id]
                control.addOverlay(gpx, value.name)
          ).bind(track)
        ).addTo(map)
