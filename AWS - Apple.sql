--1) Symbology Coverage table for every security in the FactSet ecosystem, finding the relevant FSYM_IDs
SELECT TOP 10 *
FROM sym_v1.sym_coverage;

--2) Entity Coverage table for all entities in the FactSet ecosystem, including Individuals, public companies, subsidiaries, funds, etc.
SELECT TOP 10 *
FROM ent_v1.ent_entity_coverage;

--3) Find IDs FROM a FactSet Ticker
SELECT a.ticker_region, b.proper_name, a.fsym_id, c.factset_entity_id, d.sedol, e.isin, f.cusip, b.fsym_primary_equity_id, b.fsym_primary_listing_id, b.fsym_regional_id
FROM sym_v1.sym_ticker_region a
JOIN sym_v1.sym_coverage b on a.fsym_id = b.fsym_id
JOIN sym_v1.sym_sec_entity c on b.fsym_security_id = c.fsym_id
JOIN sym_v1.sym_sedol d on a.fsym_id = d.fsym_id
JOIN sym_v1.sym_isin e on b.fsym_security_id = e.fsym_id
JOIN sym_v1.sym_cusip f on b.fsym_security_id = f.fsym_id
WHERE a.ticker_region = 'AAPL-US';

--4) Share price for Apple
SELECT TOP 10 tr.ticker_region, p.*
FROM fgp_v1.fgp_global_prices p
JOIN fgp_v1.fgp_sec_coverage fsc ON p.fsym_id = fsc.fsym_id
JOIN sym_v1.sym_coverage sc ON fsc.fsym_id = sc.fsym_primary_listing_id
JOIN sym_v1.sym_ticker_region tr ON sc.fsym_id = tr.fsym_id
WHERE tr.ticker_region = 'AAPL-US'
ORDER BY price_date DESC;

--5) Fundamentals for Apple
SELECT TOP 10 tr.ticker_region, f.*
FROM ff_v3.ff_basic_af f
JOIN ff_v3.ff_sec_coverage sc ON f.fsym_id = sc.fsym_id
JOIN sym_v1.sym_ticker_region tr ON sc.fsym_id = tr.fsym_id
WHERE tr.ticker_region = 'AAPL-US'
ORDER BY date DESC;

--6) GeoRev for Apple
SELECT tr.ticker_region,se.factset_entity_id,cov.proper_name,r.period_end_date,i.iso_country,cr.country_name,i.est_pct,i.certainty_class,i.certainty_rank
FROM sym_v1.sym_ticker_region AS tr
JOIN sym_v1.sym_coverage AS cov ON tr.fsym_id = cov.fsym_id
JOIN gr_v2.gr_sec_entity_hist AS se ON se.fsym_id = cov.fsym_security_id AND se.end_date IS NULL
JOIN gr_v2.gr_coverage AS gcov ON gcov.factset_entity_id = se.factset_entity_id
JOIN gr_v2.gr_report AS r ON r.factset_entity_id = se.factset_entity_id AND r.period_end_date like '2021%' AND r.end_date IS NULL
JOIN gr_v2.gr_item AS i ON i.report_id = r.report_id AND i.end_date IS NULL
JOIN gr_v2.gr_country_region AS cr ON cr.iso_country = i.iso_country AND cr.effective_start_date <= r.period_end_date AND (cr.effective_end_date > r.period_end_date OR cr.effective_end_date IS NULL) AND cr.end_date IS NULL
WHERE tr.ticker_region = 'AAPL-US' AND r.period_end_date like '2021%'
ORDER BY est_pct DESC;

--7) Consensus Recommendations for Apple
SELECT TOP 10 tr.ticker_region, r.*
FROM fe_v4.fe_basic_conh_rec r
JOIN fe_v4.fe_sec_coverage sc ON r.fsym_id = sc.fsym_id
JOIN sym_v1.sym_ticker_region tr ON sc.fsym_id = tr.fsym_id
WHERE tr.ticker_region = 'AAPL-US'
ORDER BY cons_start_Date DESC;

--8) DMS - Securities under an Entity
SELECT se.start_date, se.end_date, se.factset_entity_id, en.entity_proper_name, sc.fsym_id, proper_name, active_flag, fref_security_type_desc AS security_type
FROM   sym_v1.sym_sec_entity_hist AS se
JOIN sym_v1.sym_entity AS en ON en.factset_entity_id = se.factset_entity_id
JOIN sym_v1.sym_coverage AS sc ON sc.fsym_security_id = se.fsym_id
JOIN ref_v2.fref_security_type_map AS sm ON sm.fref_security_type_code = sc.fref_security_type
WHERE  se.factset_entity_id = '000C7F-E'
ORDER BY fref_security_type ASC;

--9) DMS - Entities under Ultimate Parent
SELECT es.start_date,es.end_date,es.factset_entity_id, se1.entity_proper_name, ISNULL(es.factset_parent_entity_id, es.factset_ult_parent_entity_id) AS factset_parent_entity_id , ISNULL(se2.entity_proper_name, se3.entity_proper_name) AS parent_name, es.factset_ult_parent_entity_id, se3.entity_proper_name AS ultimate_parent_name ,es.depth
FROM ent_v1.ent_entity_str_hist AS es
JOIN sym_v1.sym_entity AS se1  ON se1.factset_entity_id = es.factset_entity_id
LEFT JOIN sym_v1.sym_entity AS se2 ON se2.factset_entity_id = es.factset_parent_entity_id
JOIN sym_v1.sym_entity AS se3  ON se3.factset_entity_id = es.factset_ult_parent_entity_id
WHERE es.factset_ult_parent_entity_id = '000C7F-E' AND es.end_date IS NULL
ORDER BY parent_name DESC;

--10) Non-Institutional stakeholders
SELECT    cov.proper_name AS Company_Name, sd.factset_entity_id AS Stakeholder_ID, ent.entity_proper_name AS Stakeholder_Name, sd.report_date, sd.position, ROUND((position / p.adj_shares_outstanding) * 100.0, 2) AS Pct_OS
FROM      sym_v1.sym_ticker_region AS TR
JOIN sym_v1.sym_coverage AS cov ON tr.fsym_id = cov.fsym_id
JOIN own_v5.own_sec_map AS sm ON sm.fsym_id = cov.fsym_primary_equity_id
JOIN own_v5.own_stakes_detail AS sd ON sm.fsym_id = sd.fsym_id
JOIN
(
    SELECT d.factset_entity_id, 
           d.fsym_id, 
           MAX(d.report_date) AS max_report_date
    FROM   own_v5.own_stakes_detail AS d
    WHERE  d.report_date >= DATEADD(day, -730, '2021-10-31') AND d.report_date < '2021-10-31'
    GROUP BY d.factset_entity_id, d.fsym_id
) AS md ON md.factset_entity_id = sd.factset_entity_id AND md.max_report_date = sd.report_date AND md.fsym_id = sd.fsym_id
JOIN sym_v1.sym_entity AS ent ON ent.factset_entity_id = sd.factset_entity_id
JOIN own_v5.own_sec_prices AS p ON p.fsym_id = sd.fsym_id
JOIN
(
    SELECT p2.fsym_id, 
           MAX(price_date) AS max_p_date
    FROM   own_v5.own_sec_prices AS p2
    GROUP BY p2.fsym_id
) AS p_date ON p_date.fsym_id = p.fsym_id AND p_date.max_p_date = p.price_date
WHERE tr.ticker_region = 'AAPL-US'
ORDER BY position DESC;

-- 11) RBICS - Historical segments 
SELECT tr.ticker_region, cov.proper_name, ent.entity_proper_name, r.period_end_date, r.start_date, r.end_date, b.bus_seg_name, ROUND(b.revenue_pct, 2) AS revenue_pct, l1_name, l2_name, l3_name, l4_name, l5_name, l6_name
FROM sym_v1.sym_ticker_region AS tr
JOIN sym_v1.sym_coverage AS cov ON tr.fsym_id = cov.fsym_id
JOIN rbics_v1.rb_sec_entity_hist AS e ON e.fsym_id = cov.fsym_security_id
JOIN sym_v1.sym_entity AS ent ON ent.factset_entity_id = e.factset_entity_id
JOIN rbics_v1.rbics_bus_seg_report AS r ON r.factset_entity_id = e.factset_entity_id AND e.start_date <= r.period_end_date AND r.end_date IS NULL
JOIN rbics_v1.rbics_bus_seg_item AS b ON r.report_id = b.report_id AND b.end_date IS NULL
JOIN rbics_v1.rbics_structure AS s ON b.l6_id = s.l6_id AND s.end_date IS NULL
WHERE tr.ticker_region = 'AAPL-US'
ORDER BY period_end_date DESC;

-- 12) Supply Chain - Relationship by source
SELECT sr.id, rm.rel_type_desc, se1.entity_proper_name AS source_entity, se2.entity_proper_name AS target_entity, sr.start_date, sr.end_date, sr.revenue_pct
FROM sym_V1.sym_ticker_region AS tr
JOIN sym_V1.sym_coverage AS sc ON sc.fsym_id = tr.fsym_id
JOIN ent_V1.ent_scr_sec_entity_hist AS se ON se.fsym_id = sc.fsym_security_id
JOIN ent_V1.ent_scr_relationships AS sr ON sr.source_factset_entity_id = se.factset_entity_id
JOIN ref_v2.relationship_type_map AS rm ON rm.rel_type_code = sr.rel_type
JOIN sym_v1.sym_entity AS se1 ON se1.factset_entity_id = sr.source_factset_entity_id
JOIN sym_v1.sym_entity AS se2 ON se2.factset_entity_id = sr.target_factset_entity_id
WHERE  ticker_region = 'AAPL-US' AND se.end_date IS NULL AND sr.end_date IS NULL
ORDER BY revenue_pct DESC;

-- 13) Supply Chain - Relationship by target
SELECT sr.id, rm.rel_type_desc, se1.entity_proper_name AS source_name, se2.entity_proper_name AS target_name, sr.start_date, sr.end_date, sr.revenue_pct
FROM sym_V1.sym_ticker_region AS tr
JOIN sym_V1.sym_coverage AS sc ON sc.fsym_id = tr.fsym_id
JOIN ent_V1.ent_scr_sec_entity_hist AS se ON se.fsym_id = sc.fsym_security_id
JOIN ent_V1.ent_scr_relationships AS sr ON sr.target_factset_entity_id = se.factset_entity_id
JOIN ref_v2.relationship_type_map AS rm ON rm.rel_type_code = sr.rel_type
JOIN sym_v1.sym_entity AS se1 ON se1.factset_entity_id = sr.source_factset_entity_id
JOIN sym_v1.sym_entity AS se2 ON se2.factset_entity_id = sr.target_factset_entity_id
WHERE  ticker_region = 'AAPL-US' AND se.end_date IS NULL AND sr.end_date IS NULL
ORDER BY revenue_pct DESC;

-- 14) Supply Chain - Identifying suppliers and customers
SELECT es.id, se1.entity_proper_name AS supplier_name, se2.entity_proper_name AS customer_name, se3.entity_proper_name AS source_name, es.start_date, es.end_date, es.revenue_pct
FROM sym_V1.sym_ticker_region AS tr
JOIN sym_V1.sym_coverage AS sc ON sc.fsym_id = tr.fsym_id
JOIN ent_V1.ent_scr_sec_entity_hist AS se ON se.fsym_id = sc.fsym_security_id
JOIN ent_v1.ent_scr_supply_chain AS es ON es.customer_factset_entity_id = se.factset_entity_id OR es.supplier_factset_entity_id = se.factset_entity_id
JOIN sym_v1.sym_entity AS se1 ON se1.factset_entity_id = es.supplier_factset_entity_id
JOIN sym_v1.sym_entity AS se2 ON se2.factset_entity_id = es.customer_factset_entity_id
JOIN sym_v1.sym_entity AS se3 ON se3.factset_entity_id = es.source_factset_entity_id
WHERE  ticker_region = 'AAPL-US' AND se.end_date IS NULL AND es.end_date IS NULL
ORDER BY revenue_pct DESC;

-- 15) LinkUp - job postings
SELECT m.factset_id, j.*
FROM lu_v1.lu_jobs j
JOIN lu_v1.lu_factset_id_map m ON j.lu_company_id = m.provider_id
WHERE m.factset_id='000C7F-E';

-- 16) RBICS Hierarchy - Negative Screening
SELECT sector_id, sector_name, depth, sector_path
FROM   hier_v1.hier_sector_structure
WHERE  end_date IS NULL AND sector_id IN('273983', '30960352', '268898', '261688', '117727237','260712', '136922147', '261925', '261918', '268641')
ORDER BY sector_path;

-- 17) RBICS Hierarchy - Companies that have a focus in certain sectors
SELECT s.entity_proper_name, f.sector_id, st.sector_name, f.key_focused_flag, p.key_pureplay_flag
FROM   hier_v1.hier_sector_focus AS f
LEFT JOIN hier_v1.hier_sector_pureplay AS p ON p.factset_entity_id = f.factset_entity_id AND p.sector_id = f.sector_id AND p.end_date IS NULL AND f.end_date IS NULL
JOIN hier_v1.hier_sector_structure AS st ON st.sector_id = f.sector_id AND st.end_date IS NULL
JOIN sym_v1.sym_entity AS s ON s.factset_entity_id = f.factset_entity_id
WHERE  f.sector_id = '30960352' AND f.end_date IS NULL AND p.end_date IS NULL AND key_focused_flag = 1
ORDER BY entity_proper_name;

-- 18) TVL - ESG Ranks -   includes several elements spanning from Adjusted Insight Scores to Industry Percentiles, and ultimately a high level ESG rank categorization
SELECT top 10 r.*
FROM tv_v2.tv_esg_ranks r
JOIN tv_v2.tv_factset_id_map m ON r.tv_org_id = m.provider_id
WHERE m.factset_id ='000C7F-E'
ORDER BY r.tv_date DESC;

-- 19) TVL - Insight Scores - Provides measures of a company's long-term ESG performance that is less sensitive to daily events.
SELECT top 10 i.*
FROM tv_v2.tv_insight i
JOIN tv_v2.tv_factset_id_map m ON i.tv_org_id = m.provider_id
WHERE m.factset_id ='000C7F-E'
ORDER BY tv_date DESC;

-- 20) TVL - Momentum Scores - Captures the trend of a given company by measuring the trajectory of the Insight Score over a trailing twelve-month period.
SELECT top 10 mo.*
FROM tv_v2.tv_momentum mo
JOIN tv_v2.tv_factset_id_map ma ON mo.tv_org_id = ma.provider_id
WHERE ma.factset_id ='000C7F-E'
ORDER BY tv_date DESC;

-- 21) TVL - Pulse Scores - Measures the short-term, real-time ESG performance, focusing on the events of the day to alert investors to dynamic changes.
SELECT top 10 p.*
FROM tv_v2.tv_pulse p
JOIN tv_v2.tv_factset_id_map m ON p.tv_org_id = m.provider_id
WHERE m.factset_id ='000C7F-E'
ORDER BY tv_date DESC;

-- 22) TVL - Spotlight - Provides a daily collection of the most important positive and negative ESG events detected by Truvalue, with a variety of quantitative metadata to enable timely and systematic trading strategies and portfolio management. Qualitive informational data points such as the headline and key bullet points for articles is also included.
SELECT top 10 s.*
FROM tv_v2.tv_spotlight s
JOIN tv_v2.tv_factset_id_map m ON s.tv_org_id = m.provider_id
WHERE m.factset_id ='000C7F-E'
ORDER BY first_article_date DESC;

-- 23) TVL - Volume - Supplies the number of unique articles for each company over a trailing twelve-month period.
SELECT top 10 v.*
FROM tv_v2.tv_volume v
JOIN tv_v2.tv_factset_id_map m ON v.tv_org_id = m.provider_id
WHERE m.factset_id ='000C7F-E'
ORDER BY tv_date DESC;

-- 24) TVL - Volume pct - Provides the percentage of articles tagged for each category for a company over a trailing twelve-month period.
SELECT top 10 vp.*
FROM tv_v2.tv_volume_pctl vp
JOIN tv_v2.tv_factset_id_map m ON vp.tv_org_id = m.provider_id
WHERE m.factset_id ='000C7F-E'
ORDER BY tv_date DESC;