
		use sdfdemo;
		declare @fdate date
		set @fdate = ('2020-12-31');
			-- Coverage of All Report IDs Respective  RBICS
	WITH test AS (SELECT * FROM RBICS_V1.RBICS_BUS_SEG_ITEM AS r
					WHERE r.start_date <= @fdate
						AND (r.end_date > @fdate OR r.end_date IS NULL)),

		-- Identify Last Reporting Date with Factset-E, Solve Most Recent Rating
			max_period AS (SELECT factset_entity_id, MAX(period_end_date) AS period_end_date
						FROM   RBICS_V1.RBICS_BUS_SEG_REPORT
						WHERE  start_date <= @fdate
								AND (END_DATE > @fdate OR END_DATE IS NULL)        -- Entry Must Only be terminated After 31-Dec OR NOT Terminated
								AND period_end_date >= DATEADD(month, -24, @fdate) -- From Population, Latest Entry Not More 24Mths Ago
								group by factset_entity_id),                       -- Requirement in Microsoft MYSQL to use Groupby

		-- Map Report ID to Factset-E, Using Only Recent Entries                 
			map_segments  AS (SELECT ri.REPORT_ID, ri.FACTSET_ENTITY_ID FROM RBICS_V1.RBICS_BUS_SEG_REPORT AS ri
							join max_period as mp 
							on mp.factset_entity_id=ri.factset_entity_id and mp.period_end_date=ri.period_end_date -- Take Entries matching last known date, hence Classification 
							WHERE start_date <= @fdate                                                             -- For the same reporting date, there may be multiple entries indicating which is valid 
							AND (END_DATE > @fdate OR END_DATE IS NULL)),                                                                                                                                                 

			combined AS (SELECT test.item_id,test.L6_ID, test.REPORT_ID,test. REVENUE_PCT,test.START_DATE, test.BUS_SEG_NAME, 
								map_segments.FACTSET_ENTITY_ID  
						FROM test JOIN map_segments ON map_segments.REPORT_ID = test.REPORT_ID),

			-- Filter Primary Equity ID Securities,Use FSYM_ID to Map Primary Securities to Factset-E   
			map_FYSM AS (SELECT DISTINCT i.ISIN, 
						cov.PROPER_NAME, 
						ent.FACTSET_ENTITY_ID
				FROM SYM_V1.SYM_ISIN AS i 
				JOIN SYM_V1.SYM_COVERAGE AS cov
						ON i.FSYM_ID = cov.FSYM_ID
						AND cov.FSYM_ID = cov.FSYM_PRIMARY_EQUITY_ID
				JOIN RBICS_V1.RB_SEC_ENTITY_HIST AS ent
						ON ent.FSYM_ID = cov.FSYM_ID
						AND  ent.START_DATE <= @fdate
						AND (ent.END_DATE > @fdate OR ent.END_DATE IS NULL))     

		--SELECT 
		--    COUNT(DISTINCT map_FYSM.FACTSET_ENTITY_ID) as '3-intersection_count'
		--    FROM map_FYSM
		--    LEFT JOIN combined 
		--    ON map_FYSM.FACTSET_ENTITY_ID = combined.FACTSET_ENTITY_ID


-- To get the list of ISIN, entity ID that are missing when joining "combined" and "map_FSYM" sub queries.
		select distinct isin,factset_entity_id from (
		select map_FYSM.isin, map_FYSM.factset_entity_id, combined.factset_entity_id as comb_factset_entity_id from map_FYSM 
		LEFT JOIN combined 
			ON map_FYSM.FACTSET_ENTITY_ID = combined.FACTSET_ENTITY_ID
			) x where comb_factset_entity_id is null

 --The list of entities that are not covered in RBICS_BUS_SEG_REPORT

		--select distinct factset_entity_id from(
		--select a.*, b.factset_entity_id as rbics_entity_id from map_FYSM a
		--left join RBICS_V1.RBICS_BUS_SEG_REPORT b on a.factset_entity_id = b.factset_entity_id
		--) x where rbics_entity_id is null

--select distinct factset_entity_id from (
--select a.item_id as comb_item, a.factset_entity_id, b.* from combined a join RBICS_V1.RBICS_BUS_SEG_ITEM b on a.report_id = b.report_id
--WHERE b.start_date <= @fdate
--						AND (b.end_date > @fdate OR b.end_date IS NULL)
--) x


--select * from map_segments

--select count(distinct(factset_entity_id)) from combined -- 49307
--select count(distinct(factset_entity_id)) from map_FYSM --52770