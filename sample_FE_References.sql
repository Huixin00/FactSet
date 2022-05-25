-- Referencing RPD:17259431
-- Annual P/E through FP Price / ANN EPS
select
	a.fs_perm_sec_id
	,a.date
	,a.currency
	,a.fe_item
	,a.fe_fp_end
	,a.fe_mean
	,'date'=isnull(c.date, isnull(p.date, p2.date))
	,'Spinoff Adj Price' = isnull(fp_v1.fp_spinoffAdjPrice(c.fs_perm_sec_id, c.date), isnull(fp_v1.fp_spinoffAdjPrice(p.fs_perm_sec_id, p.date)
	,fp_v1.fp_spinoffAdjPrice(p2.fs_perm_sec_id, p2.date)))
	,'PE'=isnull(fp_v1.fp_spinoffAdjPrice(c.fs_perm_sec_id, c.date), isnull(fp_v1.fp_spinoffAdjPrice(p.fs_perm_sec_id, p.date)
	,fp_v1.fp_spinoffAdjPrice(p2.fs_perm_sec_id, p2.date)))/a.fe_mean
from fe_v2.fe_basic_conm_af a 
left join fp_v1.fp_basic_bd c on a.fs_perm_sec_id=c.fs_perm_sec_id and a.date=c.date
left join fp_v1.fp_basic_bd p on p.fs_perm_sec_id=a.fs_perm_sec_id and dateadd(dd,-1,a.date)=p.date
left join fp_v1.fp_basic_bd p2 on p2.fs_perm_sec_id=a.fs_perm_sec_id and dateadd(dd,-2,a.date)=p2.date
where a.fe_item='EPS' and a.fs_perm_sec_id='XQ818C-S-KR' and a.fe_per_rel='1'
order by a.date desc


-- #2 Convert to modern day SDF tables, fp
-- #2 Sample ANN P/E with FP and Estimates (Rolling)
--- AAPL-US = 'MH33D6-R'

SELECT
	a.[fsym_id]
	,a.[cons_end_date]
	,a.[currency]
	,a.[fe_item]
	,a.[fe_fp_end]
	,a.[fe_mean]
	,'Date'=ISNULL(c.[p_date], ISNULL(p.[p_date], p2.[p_date]))
	,'Split Adj Price' = ISNULL([fp_v2].[fp_splitadjprice](c.[fsym_id], c.[p_date]), ISNULL([fp_v2].[fp_splitadjprice](p.[fsym_id], p.[p_date])
	,[fp_v2].[fp_splitadjprice](p2.[fsym_id], p2.[p_date])))
	,'PE'=ISNULL([fp_v2].[fp_splitadjprice](c.[fsym_id], c.[p_date]), ISNULL([fp_v2].[fp_splitadjprice](p.[fsym_id], p.[p_date])
	,[fp_v2].[fp_splitadjprice](p2.[fsym_id], p2.[p_date])))/a.[fe_mean]
FROM [fe_v4].[fe_basic_conh_af] a
LEFT JOIN [fp_v2].[fp_basic_prices] c
	ON a.[fsym_id]=c.[fsym_id]
	AND a.[cons_end_date]=c.[p_date]
LEFT JOIN [fp_v2].[fp_basic_prices] p
	ON a.[fsym_id]=p.[fsym_id]
	AND DATEADD(DD,-1,a.[cons_end_date])=p.[p_date]
LEFT JOIN [fp_v2].[fp_basic_prices] p2
	ON a.[fsym_id]=p2.[fsym_id]
	AND DATEADD(DD,-1,a.[cons_end_date])=p2.[p_date]
WHERE a.[fe_item]='EPS' AND a.[fsym_id] = 'MH33D6-R' AND a.[fe_per_rel] = '1' --AND p.[p_date] >= '2019-04-26'


-- #3 Convert to modern day SDF tables
-- #3 Sample ANN P/E with FGP and Estimates (Rolling)
--- AAPL-US = 'MH33D6-R'
SELECT
	a.[fsym_id]
	,a.[cons_end_date]
	,a.[currency]
	,a.[fe_item]
	,a.[fe_fp_end]
	,a.[fe_mean]
	,'Date'=ISNULL(c.[price_date], ISNULL(p.[price_date], p2.[price_date]))
	,'Split Adj Price' = ISNULL([fgp_v1].[fgp_SplitAdjPrice](c.[fsym_id], c.[price_date]), ISNULL([fgp_v1].[fgp_SplitAdjPrice](p.[fsym_id], p.[price_date])
	,[fgp_v1].[fgp_SplitFactorPrice](p2.[fsym_id], p2.[price_date])))
	,'P/E'=ISNULL([fgp_v1].[fgp_SplitAdjPrice](c.[fsym_id], c.[price_date]), ISNULL([fgp_v1].[fgp_SplitAdjPrice](p.[fsym_id], p.[price_date])
	,[fgp_v1].[fgp_SplitAdjPrice](p2.[fsym_id], p2.[price_date])))/a.[fe_mean]
FROM [fe_v4].[fe_basic_conh_af] a
LEFT JOIN [fgp_v1].[fgp_global_prices] c
	ON a.[fsym_id]=c.[fsym_id]
	AND a.[cons_end_date]=c.[price_date]
LEFT JOIN [fgp_v1].[fgp_global_prices] p
	ON a.[fsym_id]=p.[fsym_id]
	AND DATEADD(DD,-1,a.[cons_end_date])=p.[price_date]
LEFT JOIN [fgp_v1].[fgp_global_prices] p2
	ON a.[fsym_id]=p2.[fsym_id]
	AND DATEADD(DD,-1,a.[cons_end_date])=p2.[price_date]
WHERE a.[fe_item]='EPS' AND a.[fsym_id] = 'MH33D6-R' AND a.[fe_per_rel] = '1' AND p.[price_date] >= '2019-04-26'


-- #4 Sample NTM EPS with through FP
-- Referencing from RPD:96378806
--- AAPL-US = 'MH33D6-R'
DECLARE @TICKER VARCHAR(12) = 'AAPL-US'
DECLARE @DATAITEM VARCHAR(255) = 'EPS'
DECLARE @STARTDATE DATE = '2021'
DECLARE @ENDDATE DATE = GETDATE()
SELECT TICKER_REGION
      ,P.P_DATE
      ,P.P_PRICE
         ,FY1.FE_MEAN AS FY1_MEAN
         ,FY2.FE_MEAN AS FY2_MEAN
   ,ROUND((FY1.FE_MEAN * CAST(DATEDIFF(DAY, FY2.FE_FP_END, DATEADD(YEAR, 1, P.P_DATE)) AS FLOAT) / CAST(DATEDIFF(DAY, FY2.FE_FP_END, FY1.FE_FP_END) AS FLOAT)) + (FY2.FE_MEAN * CAST(DATEDIFF(DAY, DATEADD(YEAR, 1, P.P_DATE), FY1.FE_FP_END) AS FLOAT) / CAST(DATEDIFF(DAY, FY2.FE_FP_END, FY1.FE_FP_END) AS FLOAT)), 6) AS NTM_EPS
  FROM FP_V2.FP_BASIC_PRICES P
  JOIN SYM_V1.SYM_TICKER_REGION T ON P.FSYM_ID = T.FSYM_ID
  JOIN (SELECT * FROM FE_V4.FE_BASIC_CONH_AF WHERE FE_ITEM = @DATAITEM AND FE_PER_REL = 1) FY1 ON P.FSYM_ID = FY1.FSYM_ID AND P.P_DATE BETWEEN FY1.CONS_START_DATE AND COALESCE(FY1.CONS_END_DATE, GETDATE())
  JOIN (SELECT * FROM FE_V4.FE_BASIC_CONH_AF WHERE FE_ITEM = @DATAITEM AND FE_PER_REL = 2) FY2 ON P.FSYM_ID = FY2.FSYM_ID AND P.P_DATE BETWEEN FY2.CONS_START_DATE AND COALESCE(FY2.CONS_END_DATE, GETDATE())
  WHERE TICKER_REGION = @TICKER
  AND P.P_DATE BETWEEN @STARTDATE AND @ENDDATE
  ORDER BY TICKER_REGION, P.P_DATE DESC 

--- #5 Sample NTM EPS with through FGP
-- DECLARE @TICKER VARCHAR(12) = 'AAPL-US'
DECLARE @DATAITEM VARCHAR(255) = 'EPS'
DECLARE @STARTDATE DATE = '2018'
DECLARE @ENDDATE DATE = GETDATE()
SELECT 
	[ticker_region]
      ,P.[price_date]
      ,P.[price]
         ,FY1.[fe_mean] AS FY1_MEAN
         ,FY2.[fe_mean] AS FY2_MEAN
   ,ROUND((FY1.[fe_mean] * CAST(DATEDIFF(DAY, FY2.[fe_fp_end], DATEADD(YEAR, 1, P.[price_date])) AS FLOAT) / CAST(DATEDIFF(DAY, FY2.[fe_fp_end], FY1.[fe_fp_end]) AS FLOAT)) + (FY2.[fe_mean] * CAST(DATEDIFF(DAY, DATEADD(YEAR, 1, P.[price_date]), FY1.[fe_fp_end]) AS FLOAT) / CAST(DATEDIFF(DAY, FY2.[fe_fp_end], FY1.[fe_fp_end]) AS FLOAT)), 6) AS NTM_EPS
  FROM [fgp_v1].[fgp_global_prices] P
  JOIN [sym_v1].[sym_ticker_region] T
	ON P.[fsym_id] = T.[fsym_id]
  JOIN (SELECT * FROM [fe_v4].[fe_basic_conh_af] WHERE [fe_item] = @DATAITEM AND [fe_per_rel] = 1) FY1
	ON P.[fsym_id] = FY1.[fsym_id] AND P.[price_date] BETWEEN FY1.[cons_start_date] AND COALESCE(FY1.[cons_end_date], GETDATE())
  JOIN (SELECT * FROM [fe_v4].[fe_basic_conh_af] WHERE [fe_item] = @DATAITEM AND [fe_per_rel] = 2) FY2
	ON P.[fsym_id]= FY2.[fsym_id] AND P.[price_date] BETWEEN FY2.[cons_start_date] AND COALESCE(FY2.[cons_end_date], GETDATE())
  WHERE T.[ticker_region] IN ('AAPL-US')
  AND P.[price_date] BETWEEN @STARTDATE AND @ENDDATE
  ORDER BY T.[ticker_region], P.[price_date] ASC 