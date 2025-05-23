WITH RECURSIVE info AS (
  SELECT (now() - '10 years'::interval)::date::timestamp start
), dates AS (
  SELECT info.start FROM info
  UNION ALL
  SELECT dates.start + '1 month'::interval
  FROM dates
  WHERE dates.start <= now() - '1 month'::interval
), source AS (
SELECT lpad(extract(month FROM original_timestamp)::text, '2', '0') || '.' || extract(year FROM original_timestamp) ddyyyy,
       COUNT(*) cc
 FROM photos, info
   WHERE original_timestamp IS NOT NULL AND original_timestamp >= info.start
    GROUP BY 1
), result AS (
SELECT lpad(extract(month FROM start)::text, '2', '0') || '.' || extract(year FROM start) ddyyyy, start
  FROM dates
), final AS (
SELECT result.ddyyyy,
       COALESCE(source.cc, 0) cc,
       SUM(source.cc) OVER (ORDER BY result.start) summ,
       result.start
  FROM result
    LEFT JOIN source ON source.ddyyyy = result.ddyyyy
)
SELECT ddyyyy "month", cc "count" FROM final
  WHERE summ IS NOT NULL
    ORDER BY start
