SELECT COALESCE(
         TRIM(UPPER(exif->>'make')) || ' ' || TRIM(UPPER((exif->>'model'))),
         '<none>'
       ) camera,
       COUNT(*) count
FROM photos
  GROUP BY camera
    ORDER BY 2 DESC
