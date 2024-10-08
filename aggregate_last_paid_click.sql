WITH last_paid_click AS (
    SELECT
        s.visitor_id,
        s.visit_date::date AS visit_date,
        s.source AS utm_source,
        s.medium AS utm_medium,
        s.campaign AS utm_campaign,
        l.lead_id,
        l.created_at::date AS lead_date,
        l.amount,
        l.closing_reason,
        l.status_id,
        ROW_NUMBER() OVER (
            PARTITION BY s.visitor_id
            ORDER BY s.visit_date DESC
        ) AS rn
    FROM
        sessions AS s
    LEFT JOIN
        leads AS l
        ON
            s.visitor_id = l.visitor_id
            AND
            s.visit_date <= l.created_at
    WHERE
        s.medium IN ('cpc', 'cpm', 'cpa', 'youtube', 'cpp', 'tg', 'social')
),

ads_costs AS (
    SELECT
        campaign_date::date AS campaign_date,
        utm_source,
        utm_medium,
        utm_campaign,
        SUM(daily_spent) AS total_cost
    FROM (
        SELECT
            campaign_date,
            utm_source,
            utm_medium,
            utm_campaign,
            daily_spent
        FROM
            vk_ads
        UNION ALL
        SELECT
            campaign_date,
            utm_source,
            utm_medium,
            utm_campaign,
            daily_spent
        FROM
            ya_ads
    ) AS ads
    GROUP BY
        campaign_date,
        utm_source,
        utm_medium,
        utm_campaign
),

aggregated_data AS (
    SELECT
        lc.visit_date,
        lc.utm_source,
        lc.utm_medium,
        lc.utm_campaign,
        COUNT(DISTINCT lc.visitor_id) AS visitors_count,
        COUNT(DISTINCT lc.lead_id) AS leads_count,
        COUNT(
            DISTINCT CASE
                WHEN
                    lc.closing_reason = 'Успешно реализовано'
                    OR lc.status_id = 142
                    THEN lc.lead_id
            END
        ) AS purchases_count,
        SUM(
            CASE
                WHEN
                    lc.closing_reason = 'Успешно реализовано'
                    OR lc.status_id = 142
                    THEN lc.amount
                ELSE 0
            END
        ) AS revenue
    FROM
        last_paid_click AS lc
    WHERE
        lc.rn = 1
    GROUP BY
        lc.visit_date,
        lc.utm_source,
        lc.utm_medium,
        lc.utm_campaign
)

SELECT
    ag.visit_date,
    ag.visitors_count,
    ag.utm_source,
    ag.utm_medium,
    ag.utm_campaign,
    ac.total_cost AS total_cost,
    ag.leads_count,
    ag.purchases_count,
    ag.revenue
FROM
    aggregated_data AS ag
LEFT JOIN
    ads_costs AS ac
    ON
        ag.visit_date = ac.campaign_date
        AND ag.utm_source = ac.utm_source
        AND ag.utm_medium = ac.utm_medium
        AND ag.utm_campaign = ac.utm_campaign
ORDER BY
    ag.revenue DESC NULLS LAST,
    ag.visit_date ASC,
    ag.visitors_count DESC,
    ag.utm_source ASC,
    ag.utm_medium ASC,
    ag.utm_campaign ASC
LIMIT 15;
