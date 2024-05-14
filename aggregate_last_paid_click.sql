WITH session_leads AS (
    SELECT
        s.visit_date::date AS visit_date,
        s.source AS utm_source,
        s.medium AS utm_medium,
        s.campaign AS utm_campaign,
        COUNT(DISTINCT s.visitor_id) AS visitors_count,
        COUNT(DISTINCT l.lead_id) AS leads_count,
        COUNT(DISTINCT CASE WHEN l.closing_reason = 'Успешно реализовано' OR l.status_id = 142 THEN l.lead_id END) AS purchases_count,
        SUM(CASE WHEN l.closing_reason = 'Успешно реализовано' OR l.status_id = 142 THEN l.amount ELSE 0 END) AS revenue
    FROM
        sessions s
    LEFT JOIN
        leads l ON s.visitor_id = l.visitor_id AND l.created_at::date = s.visit_date::date
    GROUP BY
        s.visit_date::date, s.source, s.medium, s.campaign
),
ads_costs AS (
    SELECT
        campaign_date::date AS visit_date,
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
    ) ads
    GROUP BY
        campaign_date::date, utm_source, utm_medium, utm_campaign
)
SELECT
    s.visit_date,
    s.utm_source,
    s.utm_medium,
    s.utm_campaign,
    s.visitors_count,
    COALESCE(a.total_cost, 0) AS total_cost,
    s.leads_count,
    s.purchases_count,
    s.revenue
FROM
    session_leads s
LEFT JOIN
    ads_costs a ON s.visit_date = a.visit_date AND s.utm_source = a.utm_source AND s.utm_medium = a.utm_medium AND s.utm_campaign = a.utm_campaign
ORDER BY
    s.revenue DESC NULLS LAST,
    s.visit_date,
    s.visitors_count DESC,
    s.utm_source,
    s.utm_medium,
    s.utm_campaign;