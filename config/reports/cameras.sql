WITH source AS (
SELECT COALESCE(
        TRIM(UPPER(exif->>'make')) || ' ' || TRIM(UPPER((exif->>'model'))),
         '<none>'
      ) camera,
      COUNT(*) count
FROM photos
  GROUP BY camera
), percentage AS (
SELECT source.*,
       100 * source.count / SUM(count) OVER () percent
FROM source
)
SELECT CASE WHEN camera = '<none>' OR percent < 0.33 THEN 'Прочее' ELSE camera END camera,
       SUM(count)::int count
FROM percentage
  GROUP BY 1
    ORDER BY 2 DESC
