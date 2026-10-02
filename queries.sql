-- ===========================================================
-- Queries de negocio, dataset CRM Sales Opportunities (MavenTech)
-- Base, revenue | Tablas, accounts, products, sales_team, sales_pipeline
-- ===========================================================

-- 1. Revenue total ganado (solo oportunidades cerradas como Won)
SELECT SUM(close_value) AS total_revenue
FROM sales_pipeline
WHERE deal_stage = 'Won';
-- Resultado, 10,005,534


-- 2. Revenue ganado por producto, de mayor a menor
SELECT product, SUM(close_value) AS revenue
FROM sales_pipeline
WHERE deal_stage = 'Won'
GROUP BY product
ORDER BY revenue DESC;
-- GTX Pro es el producto con más revenue, ~3.5M (más de un tercio del total)


-- 3. Win rate por producto (% de oportunidades ganadas sobre ganadas + perdidas)
SELECT
    product,
    COUNT(*) AS total_oportunidades,
    SUM(CASE WHEN deal_stage = 'Won' THEN 1 ELSE 0 END) AS ganadas,
    ROUND(
        SUM(CASE WHEN deal_stage = 'Won' THEN 1 ELSE 0 END)::NUMERIC
        / COUNT(*) * 100, 1
    ) AS win_rate_pct
FROM sales_pipeline
WHERE deal_stage IN ('Won', 'Lost')
GROUP BY product
ORDER BY win_rate_pct DESC;
-- Win rate parejo entre productos, 60% a 65%, MG Special el más alto (64.8%)
-- La diferencia de revenue entre productos viene del volumen y precio, no del win rate


-- 4. Revenue mensual y crecimiento % respecto al mes anterior (window function LAG)
SELECT
    DATE_TRUNC('month', close_date) AS mes,
    SUM(close_value) AS revenue,
    LAG(SUM(close_value)) OVER (ORDER BY DATE_TRUNC('month', close_date)) AS revenue_mes_anterior,
    ROUND(
        (SUM(close_value) - LAG(SUM(close_value)) OVER (ORDER BY DATE_TRUNC('month', close_date)))
        / LAG(SUM(close_value)) OVER (ORDER BY DATE_TRUNC('month', close_date)) * 100, 1
    ) AS crecimiento_pct
FROM sales_pipeline
WHERE deal_stage = 'Won'
GROUP BY DATE_TRUNC('month', close_date)
ORDER BY mes;
-- 10 meses de datos (marzo a diciembre 2017)
-- Patrón de sube y baja marcado mes a mes, probablemente propio del dataset sintético
-- (aclarar esto si se muestra en portfolio, no inventar una lectura de estacionalidad real)


-- 5. Performance por agente de ventas, revenue y win rate
SELECT
    sales_agent,
    SUM(CASE WHEN deal_stage = 'Won' THEN close_value ELSE 0 END) AS revenue,
    COUNT(*) AS total_oportunidades,
    ROUND(
        SUM(CASE WHEN deal_stage = 'Won' THEN 1 ELSE 0 END)::NUMERIC
        / SUM(CASE WHEN deal_stage IN ('Won', 'Lost') THEN 1 ELSE 0 END) * 100, 1
    ) AS win_rate_pct
FROM sales_pipeline
GROUP BY sales_agent
ORDER BY revenue DESC;
-- Darcel Schlecht lidera con 1.15M, más del doble del segundo puesto
-- pero con win rate similar al promedio (63.1%)
-- La diferencia se explica por volumen de pipeline gestionado (747 oportunidades vs 451
-- del segundo), no por mejor conversión


-- 6. Revenue por región (JOIN sales_pipeline + sales_team)
SELECT
    st.regional_office,
    SUM(CASE WHEN sp.deal_stage = 'Won' THEN sp.close_value ELSE 0 END) AS revenue
FROM sales_pipeline sp
JOIN sales_team st ON sp.sales_agent = st.sales_agent
GROUP BY st.regional_office
ORDER BY revenue DESC;
-- Bastante parejo entre regiones, West (3.57M) apenas por encima de Central (3.35M) y East (3.09M)
