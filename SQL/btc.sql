-- Raw data overview
-- Selecting all records to verify table structure and data availability

select *
from dbo.btc_analysis

-- Price analysis by sentiment
-- Calculating the average closing price (Close) for each emotional phase

select
	value_classification,
	avg([close]) as mean_close
from dbo.btc_analysis
group by value_classification
order by mean_close asc

-- Checking the index range

select
	value_classification,
	min([value]) as min_value,
	max([value]) as max_value,
	count(*) as count_days
from dbo.btc_analysis
group by value_classification
order by min_value


-- Price extremes by classification
-- Analyzing historical highs and lows of Bitcoin price for each market state

select
	value_classification,
	min([close]) as min_value,
	max([close]) as max_value,
	count(*) as count_days
from dbo.btc_analysis
group by value_classification
order by max_value desc


-- Average, Min, and Max price change range over a 7-day period for each market state

with pricechange7 as (
	select
		value_classification,
		[close] as current_price,
		lead([close], 7) over (order by [timestamp]) as price_7d
	from dbo.btc_analysis
)
select
	value_classification,
	avg((price_7d - current_price) / current_price) * 100 as percent_7d,
	min((price_7d - current_price) / current_price) * 100 as max_loss_percent,
	max((price_7d - current_price) / current_price) * 100 as max_profit_percent
from pricechange7 
group by value_classification
order by percent_7d desc


-- Comparative analysis of expected returns over 1, 7, and 30-day horizons

with pricechange as (
	select
		value_classification,
		[close] as current_price,
		lead([close], 1) over (order by [timestamp]) as price_1d,
		lead([close], 7) over (order by [timestamp]) as price_7d,
		lead([close], 30) over (order by [timestamp]) as price_30d
	from dbo.btc_analysis
)
select
	value_classification,
	avg((price_1d - current_price) / current_price) * 100 as percent_1d,
	avg((price_7d - current_price) / current_price) * 100 as percent_7d,
	avg((price_30d - current_price) / current_price) * 100 as percent_30d,
	count(price_1d) as count_1d,
	count(price_7d) as count_7d,
	count(price_30d) as count_30d
from pricechange 
group by value_classification
order by percent_30d desc


-- Identifying the specific day with the largest price crash of -45% during the 'Fear' state

with pricechange as(
	select
		[timestamp],
		[value] as fear_index,
		value_classification,
		[close] as start_price,
		lead([close], 7) over (order by [timestamp]) as price_7d,
		volume
	from dbo.btc_analysis
)
select top 10
	[timestamp],
	fear_index,
	value_classification,
	start_price,
	price_7d,
	((price_7d - start_price) / start_price) * 100 as weekly_percent,
	volume
from pricechange
where price_7d is not null
order by weekly_percent asc


-- Calculating the average 30-day holding period return by year

with pricechange as(
	select
		year([timestamp]) as year_time,
		[close] as current_price,
		lead([close], 30) over (order by [timestamp]) as price_30d
	from dbo.btc_analysis
)
select
	year_time,
	count(*) days_count,
	avg((price_30d - current_price) / current_price) * 100 as percent_30d
from pricechange
where price_30d is not null
group by year_time
order by year_time


-- Calculating returns separately for positive and negative price movements (7 and 30-day horizons)

;with price_30 as(
	select
		value_classification,
		[timestamp],
		[close] as current_price,
		lead([close], 30) over(order by [timestamp]) as price_30d
	from dbo.btc_analysis
), bool_exp as(
	select
		value_classification,
		((price_30d - current_price) / current_price) * 100 as change_percent,
		case
			when price_30d > current_price then 1
			else 0
		end as price_dynamic
	from price_30
)
select
	value_classification,
	count(*) as total_days,
	sum(price_dynamic) as positive_dynamic_count,
	round(avg(cast(price_dynamic as float)) * 100, 2) as win_percentage,
	round(avg(case when change_percent > 0 then change_percent end), 2) as avg_positive_percent_change,
	round(avg(case when change_percent < 0 then change_percent end), 2) as avg_negative_percent_change
from bool_exp
group by value_classification
order by win_percentage desc;
;with price_7 as(
	select
		value_classification,
		[timestamp],
		[close] as current_price,
		lead([close], 7) over(order by [timestamp]) as price_7d
	from dbo.btc_analysis
), bool_exp as(
	select
		value_classification,
		((price_7d - current_price) / current_price) * 100 as change_percent,
		case
			when price_7d > current_price then 1
			else 0
		end as price_dynamic
	from price_7
)
select
	value_classification,
	count(*) as total_days,
	sum(price_dynamic) as positive_dynamic_count,
	round(avg(cast(price_dynamic as float)) * 100, 2) as win_percentage,
	round(avg(case when change_percent > 0 then change_percent end), 2) as avg_positive_percent_change,
	round(avg(case when change_percent < 0 then change_percent end), 2) as avg_negative_percent_change
from bool_exp
group by value_classification
order by win_percentage desc;



-- Creating a view for visualization purposes

-- Average overall profit margin

create view price_change as
with pricechange as (
	select
		cast([timestamp] as date) as [date],
		value_classification,
		[close] as current_price,
		lead([close], 1) over (order by [timestamp]) as price_1d,
		lead([close], 7) over (order by [timestamp]) as price_7d,
		lead([close], 30) over (order by [timestamp]) as price_30d
	from dbo.btc_analysis
)
select
	[date],
	value_classification,
	((price_1d - current_price) / current_price) * 100 as percent_1d,
	((price_7d - current_price) / current_price) * 100 as percent_7d,
	((price_30d - current_price) / current_price) * 100 as percent_30d
from pricechange 


-- Price fluctuations over time

create view time_change as
select
	cast([timestamp] as date) as [date],
	value_classification,
	[value] as fear_greed_index,
	[close] as btc_price,
	[volume] as volume
from dbo.btc_analysis


-- 7-day and 30-day holding period returns for positive and negative price growth

create view price_move as
with both_prices as(
	select
		value_classification,
		[timestamp],
		[close] as current_price,
		lead([close], 30) over(order by [timestamp]) as price_30d,
		lead([close], 7) over(order by [timestamp]) as price_7d
	from dbo.btc_analysis
), price_30 as(
	select
		value_classification,
		30 as period_d,
		((price_30d - current_price) / current_price) * 100 as change_percent,
		case
			when price_30d > current_price then 1
			else 0
		end as price_dynamic
	from both_prices
), price_7 as(
	select
		value_classification,
		7 as period_d,
		((price_7d - current_price) / current_price) * 100 as change_percent,
		case
			when price_7d > current_price then 1
			else 0
		end as price_dynamic
	from both_prices
), combined as(
select * from price_30
union all
select * from price_7
)
select
	value_classification,
	period_d,
	count(*) as total_days,
	sum(price_dynamic) as positive_dynamic_count,
	round(avg(cast(price_dynamic as float)) * 100, 2) as win_percentage,
	round(avg(case when change_percent > 0 then change_percent end), 2) as avg_positive_percent_change,
	round(avg(case when change_percent < 0 then change_percent end), 2) as avg_negative_percent_change
from combined
group by value_classification, period_d