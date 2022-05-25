/*Equity Fund Holdings*/
DECLARE @HISTDATE DATE
DECLARE @DAYSBACK INTEGER
DECLARE @DAYSAHEAD INTEGER
declare @secid varchar(20)
declare @pricedate date

set @secid = (select fsym_company_id from own_v5.own_sec_map m join sym_v1.sym_ticker_region t on t.fsym_id = m.fsym_id where ticker_region = 'aapl-us')
SET @HISTDATE = '2017-09-30'            -- PERSPECTIVE DATE
SET @DAYSBACK = -730                     --THE NUMBER OF DAYS PRIOR TO THE @HISTDATE THAT HOLDINGS WOULD BE CONSIDERED VALID
SET @DAYSAHEAD = 0                      --THE NUMBER OF DAYS AFTER THE @HISTDATE THAT HOLDINGS WOULD BE CONSIDERED VALID
set @pricedate = (select max(price_date) from own_v5.own_sec_prices where price_date between dateadd(dd,@daysback,@histdate) and dateadd(dd,@daysahead,@histdate))

select top 15
a.factset_fund_id
,g.entity_proper_name 'Fund Name'
,round(f.adj_holding / p.adj_shares_outstanding * 100 , 2) '%OS'
,f.adj_holding 'Position'
,f.report_date 'Report Date'
,j.filing_date 'Filing Date'
,j.transfer_date 'Transfer Date'
,m.fund_type_desc 'Fund Type'
,a.style fund_style
,'Active/Passive' = 
	case 
		when a.style = 'Index'
		then 'Passive'
		when a.style is null
		then 'Other'
		else 'Active'
	end
from own_v5.own_ent_funds a
join (select factset_fund_id, max(report_date) report_date
       from own_v5.own_ent_fund_filing_hist
       where report_date between DATEADD(DD,@DAYSBACK,@HISTDATE) and DATEADD(DD,@DAYSAHEAD,@HISTDATE)
       group by factset_fund_id
       ) e on a.factset_fund_id = e.factset_fund_id
join own_v5.own_fund_detail f on e.factset_fund_id = f.factset_fund_id
  and e.report_date = f.report_date
join sym_v1.sym_entity g on a.factset_fund_id = g.factset_entity_id
join sym_v1.sym_coverage h on f.fsym_id = h.fsym_id
join own_v5.own_ent_institutions i on i.factset_entity_id = a.factset_inst_entity_id
join own_v5.own_sec_prices p on p.fsym_id = @secid and p.price_date = @pricedate
join own_v5.own_ent_fund_filing_hist j on j.factset_fund_id = f.factset_fund_id and j.report_date = f.report_date
join ref_v2.fund_type_map m on m.fund_type_code = a.fund_type
where f.fsym_id = @secid
order by adj_holding desc

