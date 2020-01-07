$(document)
  .on 'turbolinks:load', ->
    $map = $('.page-map-content')

    return unless $map.length > 0

    $.get $map.data('url'), (response) ->
      return unless response.bounds?

      $map.show()
      map = L.map('map').setView($map.data('center'), 13)

      L.tileLayer($map.data('tile_layer'), {attribution: $map.data('attribution')}).addTo(map)

      p1 = L.latLng(response.bounds.min_lat, response.bounds.min_long)
      p2 = L.latLng(response.bounds.max_lat, response.bounds.max_long)
      map.fitBounds(L.latLngBounds(p1, p2))

      markers = L.markerClusterGroup()
      $('.photo[data-lat-long]').each ->
        $this = $(this)

        $img = $('img', $this)
        title = $('.photo-name', $this).text()

        imgWidth = $img.data('width') * 200 / $img.data('height')
        imgWidth = 200 if imgWidth > 200
        imgHeight = $img.data('height') * imgWidth / $img.data('width')

        src = $img.data('src') || $img.attr('src')

        marker = L.marker(
          $this.data('lat-long'),
          title: title
        ).bindPopup(
          "<div class=\"photo-popup\"><h3>#{title}</h3><a href=\"#{$this.attr('href')}\" target=\"_blank\">" +
          "<img style=\"width: #{imgWidth}px; height: #{imgHeight}px\" src=\"#{src}\"></a></div>"
        )

        markers.addLayer(marker)

      map.addLayer(markers)

      return unless response.tracks.length > 0

      tracks = {}
      for track in response.tracks
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

            if Object.keys(tracks).length == response.tracks.length
              control = L.control.layers(null, null).addTo(map)
              for value in response.tracks
                gpx = tracks[value.id]
                control.addOverlay(gpx, value.name)
          ).bind(track)
        ).addTo(map)
