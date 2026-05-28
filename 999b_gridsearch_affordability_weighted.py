"""
Grid search with weighted OLS:
  - Weights: GDP (2010) or population (2010)
  - Specification: PTI, 2010 base, OECD only
  - End year: 2019
  - Compares unweighted vs weighted correlations
"""

import os, requests
import pandas as pd
import numpy as np
from scipy import stats

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
ROOT     = '/home/gyozo/Dropbox/claude/research/HousingFertility'
DATA_RAW = os.path.join(ROOT, 'data', 'cross_country')
CSV_IN   = os.path.join(DATA_RAW, 'cross_country_affordability.csv')

# ---------------------------------------------------------------------------
# Load affordability + TFR data (OECD only, 2010 base)
# ---------------------------------------------------------------------------
df = pd.read_csv(CSV_IN)
print(f'Loaded {len(df)} OECD countries')

# ---------------------------------------------------------------------------
# Download World Bank GDP (2010) and population (2010)
# ---------------------------------------------------------------------------
print('\nFetching World Bank GDP and population...')

# GDP (constant 2010 USD)
gdp_2010 = {}
url_gdp = 'https://api.worldbank.org/v2/country/all/indicator/NY.GDP.MKTP.KD?format=json&date=2010&per_page=500'
try:
    r = requests.get(url_gdp, timeout=90)
    data = r.json()
    for rec in (data[1] or []):
        if rec.get('value'):
            gdp_2010[rec['countryiso3code']] = float(rec['value'])
    print(f'  GDP 2010: {len(gdp_2010)} countries')
except Exception as e:
    print(f'  GDP fetch failed: {e}')

# Population (2010)
pop_2010 = {}
url_pop = 'https://api.worldbank.org/v2/country/all/indicator/SP.POP.TOTL?format=json&date=2010&per_page=500'
try:
    r = requests.get(url_pop, timeout=90)
    data = r.json()
    for rec in (data[1] or []):
        if rec.get('value'):
            pop_2010[rec['countryiso3code']] = float(rec['value'])
    print(f'  Population 2010: {len(pop_2010)} countries')
except Exception as e:
    print(f'  Population fetch failed: {e}')

# ---------------------------------------------------------------------------
# Add weights to data
# ---------------------------------------------------------------------------
df['gdp_2010'] = df['iso3'].map(gdp_2010)
df['pop_2010'] = df['iso3'].map(pop_2010)

# Normalize weights to sum=N (so standard errors are comparable)
for col in ['gdp_2010', 'pop_2010']:
    valid = df[col].dropna()
    if len(valid) > 0:
        df[col] = df[col] / df[col].mean()  # Normalize to mean=1

df_gdp = df[['iso3', 'label', 'dpti', 'dtfr', 'gdp_2010']].dropna()
df_pop = df[['iso3', 'label', 'dpti', 'dtfr', 'pop_2010']].dropna()

print(f'\nGDP weights: {len(df_gdp)} countries')
print(f'Population weights: {len(df_pop)} countries')

# ---------------------------------------------------------------------------
# Compare unweighted vs weighted OLS
# ---------------------------------------------------------------------------
results = []

def weighted_slope_r(x, y, w=None):
    """Compute slope, intercept, r, p for (optionally weighted) regression"""
    if w is None:
        slope, intercept, r, p, _ = stats.linregress(x, y)
        return slope, intercept, r, p
    else:
        # Use numpy polyfit for weighted regression
        coeffs = np.polyfit(x, y, 1, w=w)
        slope, intercept = coeffs[0], coeffs[1]
        # Compute r manually: r = correlation of y vs yhat
        yhat = slope * x + intercept
        r = np.corrcoef(y, yhat)[0, 1]
        # Rough p-value approximation (not exact for weighted)
        n = len(x)
        t = r * np.sqrt(n - 2) / np.sqrt(1 - r**2 + 1e-10)
        p = 2 * (1 - stats.t.cdf(np.abs(t), n - 2))
        return slope, intercept, r, p

# Unweighted
df_uw = df[['dpti', 'dtfr']].dropna()
x = df_uw['dpti'].values
y = df_uw['dtfr'].values
slope_uw, intercept_uw, r_uw, p_uw = weighted_slope_r(x, y)
results.append({
    'spec': 'OECD PTI 2010-2019',
    'weight': 'unweighted',
    'n': len(x),
    'r': round(r_uw, 4),
    'slope': round(slope_uw, 6),
    'p': round(p_uw, 4)
})

# GDP-weighted
if len(df_gdp) > 2:
    x = df_gdp['dpti'].values
    y = df_gdp['dtfr'].values
    w = df_gdp['gdp_2010'].values
    slope_gdp, intercept_gdp, r_gdp, p_gdp = weighted_slope_r(x, y, w)
    results.append({
        'spec': 'OECD PTI 2010-2019',
        'weight': 'GDP 2010',
        'n': len(x),
        'r': round(r_gdp, 4),
        'slope': round(slope_gdp, 6),
        'p': round(p_gdp, 4)
    })

# Population-weighted
if len(df_pop) > 2:
    x = df_pop['dpti'].values
    y = df_pop['dtfr'].values
    w = df_pop['pop_2010'].values
    slope_pop, intercept_pop, r_pop, p_pop = weighted_slope_r(x, y, w)
    results.append({
        'spec': 'OECD PTI 2010-2019',
        'weight': 'Population 2010',
        'n': len(x),
        'r': round(r_pop, 4),
        'slope': round(slope_pop, 6),
        'p': round(p_pop, 4)
    })

# ---------------------------------------------------------------------------
# Report
# ---------------------------------------------------------------------------
res = pd.DataFrame(results)
print('\n=== COMPARISON: UNWEIGHTED VS WEIGHTED OLS ===\n')
print(res.to_string(index=False))

print('\n\nInterpretation:')
print('  Unweighted: each country counts equally')
print('  GDP-weighted: larger economies influence the line more')
print('  Population-weighted: more populous countries influence the line more')
print('\n  More negative slope = stronger affordability-fertility correlation')
