CREATE TABLE nykaa_campaigns (
    id                  SERIAL PRIMARY KEY,
    campaign_id         VARCHAR(15),
    campaign_type       VARCHAR(15),
    target_audience     VARCHAR(25),
    campaign_duration   SMALLINT,
    duration_bucket     VARCHAR(15),
    channel_used        VARCHAR(30),
    impressions         BIGINT,
    clicks              BIGINT,
    total_leads         BIGINT,
    total_conversions   BIGINT,
    total_revenue       BIGINT,
    acquisition_cost    NUMERIC(10,2),
    roi                 NUMERIC(10,4),
    campaign_language   VARCHAR(20),
    engagement_score    NUMERIC(8,4),
    customer_segment    VARCHAR(25),
    date_raw            VARCHAR(15),
    is_instagram        SMALLINT,
    is_youtube          SMALLINT,
    is_whatsapp         SMALLINT,
    is_facebook         SMALLINT,
    is_google           SMALLINT,
    is_email            SMALLINT
)


select * from nykaa_campaigns;
select count(*) from nykaa_campaigns;

--Adding a new column "campaign_date" to run DATE queries (can't be using "date_raw" since its stored in TEXT format)
alter table nykaa_campaigns
add column campaign_date DATE;

UPDATE nykaa_campaigns
SET campaign_date = TO_DATE(date_raw, 'DD-MM-YYYY');

select * from nykaa_campaigns;

--count distinct per column

select
	count(distinct campaign_type) as campaign_types,
	count(distinct channel_used) as channels,
	count(distinct campaign_language) as langauges,
	count(distinct customer_segment) as customers
from nykaa_campaigns;

SELECT DISTINCT campaign_type
FROM nykaa_campaigns;

SELECT DISTINCT channel_used
FROM nykaa_campaigns;

SELECT DISTINCT campaign_language
FROM nykaa_campaigns;

SELECT DISTINCT customer_segment
FROM nykaa_campaigns;

--checking for NULL values in critical columns

select
	sum(CASE WHEN campaign_id IS NULL THEN 1 ELSE 0 END) AS null_id,
	SUM(CASE WHEN impressions IS NULL THEN 1 ELSE 0 END) AS null_impressions,
	SUM(CASE WHEN clicks IS NULL THEN 1 ELSE 0 END) AS null_clicks,
	SUM(CASE WHEN total_leads IS NULL THEN 1 ELSE 0 END) AS null_leads,
	SUM(CASE WHEN total_conversions IS NULL THEN 1 ELSE 0 END) AS null_conversions,
	SUM(CASE WHEN total_revenue IS NULL THEN 1 ELSE 0 END) AS null_revenue
from nykaa_campaigns;

--checking if there is duplicates in the primary key

select
	campaign_id, count(*) as cnt
	from nykaa_campaigns
	group by campaign_id
	having count(*) >1 ;

-- Extracting month & year from date for grouping

alter table nykaa_campaigns
add column campaign_month varchar (7);

update nykaa_campaigns
set campaign_month = to_char(campaign_date, 'yyyy-mm');

select campaign_date, campaign_month
FROM nykaa_campaigns;

--ADDING CALCULATED COLUMNS

ALTER TABLE nykaa_campaigns
    ADD COLUMN ctr               NUMERIC(10,6),
    ADD COLUMN click_to_lead     NUMERIC(10,6),
    ADD COLUMN lead_to_conv      NUMERIC(10,6),
    ADD COLUMN overall_conv      NUMERIC(10,6),
    ADD COLUMN cost_per_conv     NUMERIC(12,4),
    ADD COLUMN revenue_per_conv  NUMERIC(12,4);

UPDATE nykaa_campaigns SET
    ctr              = clicks::NUMERIC            / NULLIF(impressions, 0),
    click_to_lead    = total_leads::NUMERIC        / NULLIF(clicks, 0),
    lead_to_conv     = total_conversions::NUMERIC  / NULLIF(total_leads, 0),
    overall_conv     = total_conversions::NUMERIC  / NULLIF(impressions, 0),
    cost_per_conv    = acquisition_cost            / NULLIF(total_conversions, 0),
    revenue_per_conv = total_revenue::NUMERIC      / NULLIF(total_conversions, 0);

------------------------------------------------------------------------------------------------------------------------------------------
--Q1. How many total campaigns are in this dataset?

select 
	count(*) as total_campaigns,
	count(distinct campaign_id) as unique_campaign_id
FROM nykaa_campaigns;

--Q2. How many campaigns exist per Campaign_Type?

SELECT
	campaign_type,
	count(*) as campaigns
FROM nykaa_campaigns
group by campaign_type
order by count(*) desc;

--Q3.  What is the total revenue and average ROI across all campaigns?

select
	sum(total_revenue) as total_revenue,
	round(avg(roi),2) as avg_roi
from nykaa_campaigns;

--Q4.  Show only campaigns that generated ROI greater than 5.

SELECT
	campaign_id,
	campaign_type,
	channel_used,
	roi
from nykaa_campaigns
where roi > 5
order by roi desc

--Q5.  Find the top 5 campaigns by Revenue.

select
	campaign_id,
	campaign_type,
	channel_used,
	total_revenue,
	round(roi,2) as roi
FROM nykaa_campaigns
order by total_revenue desc
LIMIT 5;

--Q6.  Calculate Click-Through Rate (CTR) for every campaign.

select
	campaign_id,
	campaign_type,
	impressions,
	clicks,
	ctr,
	round(clicks::numeric / impressions * 100, 3) as ctr_percent
from nykaa_campaigns
order by ctr_percent desc;


--Q7.  For each Campaign_Type, show total impressions, clicks, and average CTR.

SELECT
	campaign_type,
	sum(impressions) as total_impressions,
	sum(clicks) as total_clicks,
	round(sum(clicks)::numeric / sum(impressions) * 100, 2) as avg_ctr -- USED WIEGHTED AVERAGE 
FROM nykaa_campaigns
group by campaign_type;


--Q8.  Show the complete marketing funnel with drop-off % at each stage.

SELECT
	sum(impressions) as total_impressions,
	sum(clicks) as total_clicks,
	sum(total_leads) as total_leads,
	sum(total_conversions) as total_conversions,
	round(sum(clicks)::numeric / sum(impressions) * 100, 2) as ctr_pct,
	round(sum(total_leads)::numeric / sum(clicks) * 100 , 2) as clicks_to_leads_pct,
	round(sum(total_conversions)::numeric / sum(total_leads) * 100 , 2) as leads_to_conversions_pct,
	round(sum(total_conversions)::numeric / sum(impressions) * 100 , 2) as overall_conversions_pct
from nykaa_campaigns;

--INSIGHT -> Stage 1 has the highest dropout.
--		  -> CTR shows 8.51% which means 91% of dropout is seen and needs to be taken care of.


--Q9.  Which Campaign_Types have an average ROI greater than 2.7?

SELECT
	campaign_type,
	count(*) as total_campaigns,
	sum(total_revenue) as total_revenue,
	round(avg(roi),2) as avg_roi
from nykaa_campaigns
group by campaign_type
having avg(roi) > 2.7;

--Q10. Which campaign type converts best?

SELECT
	campaign_type,
	count(*) as total_campaigns,
	sum(total_revenue) as total_revenue,
	round(avg(roi),2) as avg_roi,
	sum(impressions) as total_impressions,
	sum(clicks) as total_clicks,
	sum(total_leads) as total_leads,
	sum(total_conversions) as total_conversions,
	round(sum(clicks)::numeric / sum(impressions) * 100 , 2) as ctr_prct,
	round(sum(total_leads)::numeric / sum(clicks) * 100 , 2) as clicks_to_lead_prct,
	round(sum(total_conversions)::numeric / sum(total_leads) * 100 , 2) as leads_to_conversions_prct,
	round(sum(total_conversions)::numeric / sum(impressions) * 100 ,2) as overall_conv_prct
FROM nykaa_campaigns
GROUP BY campaign_type
ORDER BY overall_conv_prct desc;


--Q11.  Which customer segment has the best lead-to-conversion rate?

SELECT
	customer_segment,
	sum(total_revenue) as total_revenue,
	count(*) as total_campaigns,
	round(avg(roi),2) as avg_roi,
	round(sum(total_conversions)::numeric / sum(total_leads) * 100 , 2) as lead_to_conv_prct
FROM nykaa_campaigns
GROUP BY customer_segment
ORDER BY lead_to_conv_prct desc;


--Q12.  Using a CTE, find the top 3 channels by conversion rate — but only show channels with at least 1,000 campaigns.

WITH channel_funnel as (

SELECT
	channel_used,
	count(*) as total_campaigns,
	sum(impressions) as total_impressions,
	sum(total_conversions) as total_conversions,
	round(sum(total_conversions)::numeric / sum(impressions) * 100, 2) as overall_conv_prct,
	round(sum(clicks)::numeric / sum(impressions) * 100 , 2) as CTR_prct,
	round(avg(roi),2) as avg_roi
FROM nykaa_campaigns
GROUP BY channel_used
)
SELECT *
FROM channel_funnel
where total_campaigns >= 1000
ORDER BY overall_conv_prct desc
LIMIT 3;


--Q13.  Show the monthly trend of total revenue and conversion rate for 2025.

select
	campaign_month,
	count(*) as total_campaigns,
	sum(total_revenue) as total_revenue,
	sum(impressions) as total_impressions,
	sum(total_conversions) as total_conversions,
	round(sum(total_conversions)::numeric / sum(impressions) * 100 ,2) as overall_conv_prct
FROM nykaa_campaigns
where campaign_date BETWEEN '2025-01-01' AND '2025-12-31'
GROUP BY campaign_month
order by campaign_month;


--Q14. Campaign duration VS Performance

SELECT
	duration_bucket,
	count(*) as total_campaigns,
	round(sum(clicks)::numeric / sum(impressions) * 100 , 2) as CTR_prct,
	round(sum(total_leads)::numeric / sum(clicks) * 100 , 2) as clicks_to_leads_prct,
	round(sum(total_conversions)::numeric / sum(total_leads) * 100 , 2) as lead_to_conv_prct,
	round(sum(total_conversions)::numeric / sum(impressions) * 100 , 2) as overall_conv_prct,
	round(avg(roi),2) as avg_roi,
	ROUND(avg(engagement_score),2) as avg_engagement
FROM nykaa_campaigns
GROUP BY duration_bucket
ORDER BY overall_conv_prct DESC;



