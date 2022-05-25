DECLARE @id NVARCHAR(50) = 'SDR-GB';
DECLARE @requestDate date = '2020-12-30';
DECLARE @maxDate date = (
	SELECT
		MAX(latestDate)
	FROM (
		SELECT
			tr.ticker_region,
			tr.fsym_id,
			sm.fsym_company_id,
			'Quarterly' AS 'frequency',
			MAX(qf.date) AS 'latestDate'
		FROM [sym_v1].[sym_ticker_region] tr
		LEFT JOIN [ff_v3].[ff_sec_map] sm ON tr.fsym_id = sm.fsym_id
		LEFT JOIN [ff_v3].[ff_basic_qf] qf ON sm.fsym_company_id = qf.fsym_id
		WHERE tr.ticker_region IN (@id)
		AND qf.date <= @requestDate
		GROUP BY tr.ticker_region, tr.fsym_id, sm.fsym_company_id
		UNION
		SELECT
			tr.ticker_region,
			tr.fsym_id,
			sm.fsym_company_id,
			'Semi-annual' AS 'frequency',
			MAX(saf.date) AS 'latestDate'
		FROM [sym_v1].[sym_ticker_region] tr
		LEFT JOIN [ff_v3].[ff_sec_map] sm ON tr.fsym_id = sm.fsym_id
		LEFT JOIN [ff_v3].[ff_basic_saf] saf ON sm.fsym_company_id = saf.fsym_id
		WHERE tr.ticker_region IN (@id)
		AND saf.date <= @requestDate
		GROUP BY tr.ticker_region, tr.fsym_id, sm.fsym_company_id
		UNION
		SELECT
			tr.ticker_region,
			tr.fsym_id,
			sm.fsym_company_id,
			'Annual' AS 'frequency',
			MAX(af.date) AS 'latestDate'
		FROM [sym_v1].[sym_ticker_region] tr
		LEFT JOIN [ff_v3].[ff_sec_map] sm ON tr.fsym_id = sm.fsym_id
		LEFT JOIN [ff_v3].[ff_basic_af] af ON sm.fsym_company_id = af.fsym_id
		WHERE tr.ticker_region IN (@id)
		AND af.date <= @requestDate
		GROUP BY tr.ticker_region, tr.fsym_id, sm.fsym_company_id) AS temp);

--SELECT @maxDate AS maxDate;

SELECT
	tr.ticker_region,
	tr.fsym_id,
	sm.fsym_company_id,
	COALESCE(qf.date, saf.date, af.date) AS 'date',
	COALESCE(qf.ff_sales, saf.ff_sales, af.ff_sales) AS 'ff_sales',
	COALESCE(qf.ff_source_is_date, saf.ff_source_is_date, af.ff_source_is_date) AS 'ff_source_is_date',
	COALESCE(qf.ff_source_bs_date, saf.ff_source_bs_date, af.ff_source_bs_date) AS 'ff_source_bs_date',
	COALESCE(qf.ff_source_cf_date, saf.ff_source_cf_date, af.ff_source_cf_date) AS 'ff_source_cf_date'
FROM [sym_v1].[sym_ticker_region] tr
LEFT JOIN [ff_v3].[ff_sec_map] sm ON tr.fsym_id = sm.fsym_id
LEFT JOIN [ff_v3].[ff_basic_qf] qf ON sm.fsym_company_id = qf.fsym_id AND qf.date = @maxDate AND qf.ff_sales IS NOT NULL AND qf.ff_source_is_date IS NOT NULL AND qf.ff_source_bs_date IS NOT NULL AND qf.ff_source_cf_date IS NOT NULL
LEFT JOIN [ff_v3].[ff_basic_saf] saf ON sm.fsym_company_id = saf.fsym_id AND saf.date = @maxDate AND saf.ff_sales IS NOT NULL AND saf.ff_source_is_date IS NOT NULL AND saf.ff_source_bs_date IS NOT NULL AND saf.ff_source_cf_date IS NOT NULL
LEFT JOIN [ff_v3].[ff_basic_af] af ON sm.fsym_company_id = af.fsym_id AND af.date = @maxDate AND af.ff_sales IS NOT NULL AND af.ff_source_is_date IS NOT NULL AND af.ff_source_bs_date IS NOT NULL AND af.ff_source_cf_date IS NOT NULL
WHERE tr.ticker_region IN (@id);