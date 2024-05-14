WITH last_paid_click AS (
    SELECT 
        s.visitor_id,
        s.visit_date,
        s.source AS utm_source,
        s.medium AS utm_medium,
        s.campaign AS utm_campaign,
        l.lead_id,
        l.created_at,
        l.amount,
        l.closing_reason,
        l.status_id,
        ROW_NUMBER() OVER (PARTITION BY s.visitor_id ORDER BY s.visit_date DESC) AS rn
    FROM 
        sessions s
    LEFT JOIN 
        leads l ON s.visitor_id = l.visitor_id
    WHERE 
        s.medium IN ('cpc', 'cpm', 'cpa', 'youtube', 'cpp', 'tg', 'social')
)
SELECT 
    visitor_id,
    visit_date,
    utm_source,
    utm_medium,
    utm_campaign,
    lead_id,
    created_at,
    amount,
    closing_reason,
    status_id
FROM 
    last_paid_click
WHERE 
    rn = 1
ORDER BY 
    amount DESC NULLS LAST,
    visit_date,
    utm_source,
    utm_medium,
    utm_campaign;