-- FactSet Supply Chain data is Point-In-Time database
-- All records have start_date and end_date so that you can query a snapshot as of a certain date
DECLARE @date AS DATE= '2021-03-08'; --The date as-of

 

/*
FactSet Supply Chain data is organized by the
factset_entity_id: a unique identifier assigned to each entity.
To return a public company's relationships based on a market id
begin in symbology to find the following path: market id-> fsym_id ->factset_entity_id
For this example we will be using Apple Inc. locating the entity id
*/

 
WITH
--Ticker Region
ticker
AS (SELECT DISTINCT 
           tr.ticker_region, 
           cov.proper_name, 
           ent.factset_entity_id
    FROM   sym_v1.sym_ticker_region AS tr --Historical table for the US and Australian stocks is available as an add-on package
    JOIN sym_v1.sym_coverage AS cov
      ON tr.fsym_id = cov.fsym_id
    --Security to Entity Linkage is provided at the security-level
    JOIN ent_v1.ent_scr_sec_entity_hist AS ent
      ON ent.fsym_id = cov.fsym_security_id
         AND ent.start_date <= @date
         AND (ent.end_date > @date
              OR ent.end_date IS NULL)
    WHERE  tr.ticker_region IN('941-HK', '1299-HK')),
bbg_ticker
AS (SELECT DISTINCT 
           factset_entity_id, 
           bbg_ticker
    FROM   ent_v1.ent_scr_sec_entity_hist AS ent
    JOIN sym_v1.sym_coverage AS cov
      ON ent.fsym_id = cov.fsym_id
         AND cov.fsym_id = cov.fsym_primary_equity_id
    JOIN sym_v1.sym_bbg AS b
      ON b.fsym_id = cov.fsym_primary_listing_id
    WHERE  ent.start_date <= @date
           AND (ent.end_date > @date
                OR ent.end_date IS NULL))
--Return all relationships announced by the target company and/or the counter party
SELECT DISTINCT 
       rel.source_factset_entity_id, 
       sb.bbg_ticker AS 'Source BBG Ticker', 
       se.entity_proper_name AS 'Source Name', 
       se.iso_country AS 'Source Co Country', 
       rss.l2_name AS 'Source Co Industry', 
       rel.target_factset_entity_id, 
       tb.bbg_ticker AS 'Target BBG Ticker', 
       te.entity_proper_name AS 'Target Name', 
       te.iso_country AS 'Target Co Country', 
       rst.l2_name AS 'Target Co Industry', 
       rt.rel_type_desc
--rel.revenue_pct
FROM     ent_v1.ent_scr_relationships AS rel
JOIN sym_v1.sym_entity AS se
  ON rel.source_factset_entity_id = se.factset_entity_id
JOIN sym_v1.sym_entity AS te
  ON rel.target_factset_entity_id = te.factset_entity_id
-- Ties source entity ID to RBICS Level 2 ID
JOIN sym_v1.sym_entity_sector_rbics AS rbs
  ON rbs.factset_entity_id = rel.source_factset_entity_id
JOIN ref_v2.rbics_structure_l2_curr AS rss
  ON rss.l2_id = rbs.l2_id
-- Ties target entity ID to RBICS Level 2 ID
JOIN sym_v1.sym_entity_sector_rbics AS rbt
  ON rbt.factset_entity_id = rel.target_factset_entity_id
JOIN ref_v2.rbics_structure_l2_curr AS rst
  ON rst.l2_id = rbt.l2_id
JOIN ticker AS mid
  ON mid.factset_entity_id = rel.source_factset_entity_id -- Relationships announced by the selected company
JOIN ref_v2.relationship_type_map AS rt
  ON rt.rel_type_code = rel.rel_type
JOIN bbg_ticker AS sb
  ON sb.factset_entity_id = rel.source_factset_entity_id
JOIN bbg_ticker AS tb
  ON tb.factset_entity_id = rel.target_factset_entity_id
WHERE   rel.start_date <= @date
        AND (rel.end_date > @date
             OR rel.end_date IS NULL)
UNION
SELECT DISTINCT 
       rel.source_factset_entity_id, 
       sb.bbg_ticker AS 'Source BBG Ticker', 
       se.entity_proper_name AS 'Source Name', 
       se.iso_country AS 'Source Co Country', 
       rss.l2_name AS 'Source Co Industry', 
       rel.target_factset_entity_id, 
       tb.bbg_ticker AS 'Target BBG Ticker', 
       te.entity_proper_name AS 'Target Name', 
       te.iso_country AS 'Target Co Country', 
       rst.l2_name AS 'Target Co Industry', 
       rt.rel_type_desc
--rel.revenue_pct
FROM   ent_v1.ent_scr_relationships AS rel
JOIN sym_v1.sym_entity AS se
  ON rel.source_factset_entity_id = se.factset_entity_id
JOIN sym_v1.sym_entity AS te
  ON rel.target_factset_entity_id = te.factset_entity_id
-- Ties source entity ID to RBICS Level 2 ID
JOIN sym_v1.sym_entity_sector_rbics AS rbs
  ON rbs.factset_entity_id = rel.source_factset_entity_id
JOIN ref_v2.rbics_structure_l2_curr AS rss
  ON rss.l2_id = rbs.l2_id
-- Ties target entity ID to RBICS Level 2 ID
JOIN sym_v1.sym_entity_sector_rbics AS rbt
  ON rbt.factset_entity_id = rel.target_factset_entity_id
JOIN ref_v2.rbics_structure_l2_curr AS rst
  ON rst.l2_id = rbt.l2_id
JOIN ticker AS mid
  ON mid.factset_entity_id = rel.target_factset_entity_id -- Relationships announced by the counter party
JOIN ref_v2.relationship_type_map AS rt
  ON rt.rel_type_code = rel.rel_type
JOIN bbg_ticker AS sb
  ON sb.factset_entity_id = rel.source_factset_entity_id
JOIN bbg_ticker AS tb
  ON tb.factset_entity_id = rel.target_factset_entity_id
WHERE  rel.start_date <= @date
       AND (rel.end_date > @date
            OR rel.end_date IS NULL)
ORDER BY rt.rel_type_desc DESC;

 

--rel.revenue_pct DESC;