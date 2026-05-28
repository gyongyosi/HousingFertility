"""
Grid search over affordability specifications:
  - OECD measures: PTI, standardised PTI, real HP, nominal HP
  - Base years: 2005 2007 2008 2010 2012 2014 2015
  - Country samples: all | oecd_only | drop_cee (excl. CEE convergence countries)
  - End year fixed at 2019 throughout

Reports OLS slope (correlation proxy), Pearson r, N, and Hungary's residual
(positive = Hungary above the trend line).

Outputs the top 20 specifications by most-negative slope.
"""

import os, io, requests, zipfile
import pandas as pd
import numpy as np
from scipy import stats

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
ROOT     = '/home/gyozo/Dropbox/claude/research/HousingFertility'
DATA_RAW = os.path.join(ROOT, 'data', 'cross_country')
TFR_CSV  = os.path.join(ROOT, 'data', 'human_fertility',
                        'API_SP.DYN.TFRT.IN_DS2_en_csv_v2_252787.csv')

OECD_FILE = os.path.join(DATA_RAW, 'oecd_house_prices.csv')
BIS_FILE  = os.path.join(DATA_RAW, 'WS_SPP_csv_flat.csv')
GDP_FILE  = os.path.join(DATA_RAW, 'wb_gdppc_real.csv')

END_YEAR = 2019

# CEE countries to drop in 'drop_cee' sample (keep Hungary)
CEE = {'BGR', 'HRV', 'CZE', 'EST', 'LVA', 'LTU', 'POL', 'ROU',
       'SVK', 'SVN', 'RUS', 'SRB', 'MKD', 'ALB', 'BIH', 'XKX'}

# ---------------------------------------------------------------------------
# 1. Load OECD house price data (all measures)
# ---------------------------------------------------------------------------
oecd = pd.read_csv(OECD_FILE)
oecd_annual = oecd[oecd['FREQ'] == 'A'].copy()
oecd_annual['year'] = pd.to_numeric(oecd_annual['TIME_PERIOD'], errors='coerce')
oecd_annual['val']  = pd.to_numeric(oecd_annual['OBS_VALUE'],  errors='coerce')
oecd_annual = oecd_annual[['Reference area', 'Measure', 'year', 'val']].dropna()

agg_names = {'Euro area', 'Euro area (17 countries)', 'Euro area (19 countries)',
             'Euro area (20 countries)', 'OECD', 'G7', 'G20', 'OECD - Total'}
oecd_annual = oecd_annual[~oecd_annual['Reference area'].isin(agg_names)]

oecd_iso3 = {
    'Australia': 'AUS', 'Austria': 'AUT', 'Belgium': 'BEL',
    'Bulgaria': 'BGR', 'Canada': 'CAN', 'Chile': 'CHL',
    'Colombia': 'COL', 'Costa Rica': 'CRI', 'Croatia': 'HRV',
    'Czechia': 'CZE', 'Denmark': 'DNK', 'Estonia': 'EST',
    'Finland': 'FIN', 'France': 'FRA', 'Germany': 'DEU',
    'Greece': 'GRC', 'Hungary': 'HUN', 'Iceland': 'ISL',
    'Ireland': 'IRL', 'Israel': 'ISR', 'Italy': 'ITA',
    'Japan': 'JPN', 'Korea': 'KOR', 'Latvia': 'LVA',
    'Lithuania': 'LTU', 'Luxembourg': 'LUX', 'Netherlands': 'NLD',
    'New Zealand': 'NZL', 'Norway': 'NOR', 'Poland': 'POL',
    'Portugal': 'PRT', 'Romania': 'ROU', 'Russia': 'RUS',
    'Slovak Republic': 'SVK', 'Slovenia': 'SVN',
    'South Africa': 'ZAF', 'Spain': 'ESP', 'Sweden': 'SWE',
    'Switzerland': 'CHE', 'United Kingdom': 'GBR',
    'United States': 'USA',
    "China (People's Republic of)": 'CHN', 'Brazil': 'BRA',
}
oecd_annual['iso3'] = oecd_annual['Reference area'].map(oecd_iso3)
oecd_annual = oecd_annual.dropna(subset=['iso3'])

# ---------------------------------------------------------------------------
# 2. Load BIS real house prices (RHPI, 2010=100)
# ---------------------------------------------------------------------------
bis = pd.read_csv(BIS_FILE)
bis_real = bis[
    (bis['VALUE:Value'] == 'R: Real') &
    (bis['UNIT_MEASURE:Unit of measure'] == '628: Index, 2010 = 100') &
    (bis['FREQ:Frequency'] == 'Q: Quarterly')
].copy()
bis_real['year'] = bis_real['TIME_PERIOD:Time period or range'].str[:4].astype(int)
bis_real['val']  = pd.to_numeric(bis_real['OBS_VALUE:Observation Value'], errors='coerce')

bis_annual = (bis_real
              .groupby(['REF_AREA:Reference area', 'year'])['val']
              .mean().reset_index()
              .rename(columns={'REF_AREA:Reference area': 'country', 'val': 'rhpi'}))

bis_agg = {'5R: Advanced economies', '4T: Emerging market economies (aggregate)',
           'XM: Euro area', 'XW: World'}
bis_annual = bis_annual[~bis_annual['country'].isin(bis_agg)]

bis_iso3 = {
    'AT: Austria': 'AUT', 'AU: Australia': 'AUS', 'BE: Belgium': 'BEL',
    'BG: Bulgaria': 'BGR', 'BR: Brazil': 'BRA', 'CA: Canada': 'CAN',
    'CH: Switzerland': 'CHE', 'CL: Chile': 'CHL', 'CN: China': 'CHN',
    'CO: Colombia': 'COL', 'CY: Cyprus': 'CYP', 'CZ: Czechia': 'CZE',
    'DE: Germany': 'DEU', 'DK: Denmark': 'DNK', 'EE: Estonia': 'EST',
    'ES: Spain': 'ESP', 'FI: Finland': 'FIN', 'FR: France': 'FRA',
    'GB: United Kingdom': 'GBR', 'GR: Greece': 'GRC',
    'HK: Hong Kong SAR': 'HKG', 'HR: Croatia': 'HRV',
    'HU: Hungary': 'HUN', 'ID: Indonesia': 'IDN', 'IE: Ireland': 'IRL',
    'IL: Israel': 'ISR', 'IN: India': 'IND', 'IS: Iceland': 'ISL',
    'IT: Italy': 'ITA', 'JP: Japan': 'JPN', 'KR: Korea': 'KOR',
    'LT: Lithuania': 'LTU', 'LU: Luxembourg': 'LUX', 'LV: Latvia': 'LVA',
    'MA: Morocco': 'MAR', 'MK: North Macedonia': 'MKD',
    'MT: Malta': 'MLT', 'MX: Mexico': 'MEX', 'MY: Malaysia': 'MYS',
    'NL: Netherlands': 'NLD', 'NO: Norway': 'NOR', 'NZ: New Zealand': 'NZL',
    'PE: Peru': 'PER', 'PH: Philippines': 'PHL', 'PL: Poland': 'POL',
    'PT: Portugal': 'PRT', 'RO: Romania': 'ROU', 'RS: Serbia': 'SRB',
    'RU: Russia': 'RUS', 'SE: Sweden': 'SWE', 'SG: Singapore': 'SGP',
    'SI: Slovenia': 'SVN', 'SK: Slovakia': 'SVK', 'TH: Thailand': 'THA',
    'TR: Türkiye': 'TUR', 'US: United States': 'USA',
    'ZA: South Africa': 'ZAF',
}
bis_annual['iso3'] = bis_annual['country'].map(bis_iso3)
bis_annual = bis_annual.dropna(subset=['iso3'])

# ---------------------------------------------------------------------------
# 3. World Bank real GDP per capita
# ---------------------------------------------------------------------------
gdp_long = pd.read_csv(GDP_FILE)
# Extend with additional years if needed
cached_years = set(gdp_long['year'].astype(int).unique())

def fetch_wb_year(yr):
    url = ('https://api.worldbank.org/v2/country/all/indicator/NY.GDP.PCAP.KD'
           f'?format=json&date={yr}&per_page=500')
    for _ in range(3):
        try:
            r = requests.get(url, timeout=90)
            data = r.json()
            recs = data[1] if len(data) > 1 else []
            return pd.DataFrame([
                {'iso3': rec['countryiso3code'], 'year': int(rec['date']),
                 'gdppc': rec['value']}
                for rec in recs if rec.get('value') is not None
            ])
        except Exception:
            pass
    return pd.DataFrame()

for yr in [2005, 2007, 2008, 2010, 2012, 2014, 2015]:
    if yr not in cached_years:
        print(f'Fetching WB GDP per capita {yr}...')
        new = fetch_wb_year(yr)
        if not new.empty:
            gdp_long = pd.concat([gdp_long, new], ignore_index=True)

gdp_long['year'] = gdp_long['year'].astype(int)
gdp_long = gdp_long.drop_duplicates(['iso3', 'year'])
gdp_long.to_csv(GDP_FILE, index=False)

# ---------------------------------------------------------------------------
# 4. World Bank TFR
# ---------------------------------------------------------------------------
tfr_raw = pd.read_csv(TFR_CSV, skiprows=4, encoding='utf-8-sig')
tfr_raw = tfr_raw.loc[:, ~tfr_raw.columns.str.startswith('Unnamed')]
id_cols  = ['Country Name', 'Country Code', 'Indicator Name', 'Indicator Code']
tfr_long = tfr_raw.melt(
    id_vars=id_cols,
    value_vars=[c for c in tfr_raw.columns if c not in id_cols],
    var_name='year', value_name='tfr')
tfr_long['year'] = pd.to_numeric(tfr_long['year'], errors='coerce').astype('Int64')
tfr_long = tfr_long.dropna(subset=['tfr'])

def get_tfr(df, iso3, yr, tol=1):
    sub = df[df['Country Code'] == iso3].dropna(subset=['tfr'])
    if sub.empty: return np.nan
    exact = sub[sub['year'] == yr]
    if not exact.empty: return float(exact['tfr'].iloc[0])
    near = sub.iloc[(sub['year'] - yr).abs().argsort()[:1]]
    return float(near['tfr'].iloc[0]) if abs(int(near['year'].iloc[0]) - yr) <= tol else np.nan

# ---------------------------------------------------------------------------
# 5. Grid search
# ---------------------------------------------------------------------------
oecd_measures = [
    'Price to income ratio',
    'Standardised price-income ratio',
    'Real house price indices',
    'Nominal house price indices',
]

base_years  = [2005, 2007, 2008, 2010, 2012, 2014, 2015]
samples     = ['all', 'oecd_only', 'drop_cee']

results = []

for measure in oecd_measures:
    msub = oecd_annual[oecd_annual['Measure'] == measure]

    for base_year in base_years:

        # ----- OECD affordability change -----
        def oecd_val(iso3, yr):
            sub = msub[msub['iso3'] == iso3].dropna(subset=['val'])
            exact = sub[sub['year'] == yr]
            if not exact.empty: return exact['val'].iloc[0]
            near = sub.iloc[(sub['year'] - yr).abs().argsort()[:1]]
            return near['val'].iloc[0] if not near.empty and abs(near['year'].iloc[0]-yr)<=1 else np.nan

        oecd_rows = []
        for iso3 in msub['iso3'].unique():
            v0 = oecd_val(iso3, base_year)
            v1 = oecd_val(iso3, END_YEAR)
            if not (np.isnan(v0) or np.isnan(v1)):
                # For index measures: pct change; for ratio measures: pp change
                if 'ratio' in measure.lower() or 'price to' in measure.lower():
                    dpti = v1 - v0          # percentage-point change in ratio
                else:
                    dpti = (v1 - v0) / abs(v0) * 100  # % change in index
                oecd_rows.append({'iso3': iso3, 'dpti': dpti, 'src': 'OECD'})
        oecd_df = pd.DataFrame(oecd_rows)
        if oecd_df.empty:
            continue

        # ----- BIS RHPI + World Bank income (for non-OECD) -----
        gdp_0 = gdp_long[gdp_long['year'] == base_year].set_index('iso3')['gdppc']
        gdp_1 = gdp_long[gdp_long['year'] == END_YEAR].set_index('iso3')['gdppc']
        gdp_chg = ((gdp_1 - gdp_0) / gdp_0 * 100).reset_index()
        gdp_chg.columns = ['iso3', 'dgdppc']

        bis_0 = bis_annual[bis_annual['year'] == base_year].set_index('iso3')['rhpi']
        bis_1 = bis_annual[bis_annual['year'] == END_YEAR].set_index('iso3')['rhpi']
        bis_hp = ((bis_1 - bis_0) / bis_0 * 100).dropna().reset_index()
        bis_hp.columns = ['iso3', 'drhpi']

        bis_pti = (bis_hp.set_index('iso3')
                   .join(gdp_chg.set_index('iso3'), how='inner'))
        bis_pti['dpti'] = bis_pti['drhpi'] - bis_pti['dgdppc']
        bis_pti = bis_pti[['dpti']].dropna().reset_index()
        bis_pti['src'] = 'BIS+WB'

        oecd_iso_set = set(oecd_df['iso3'])
        bis_extra = bis_pti[~bis_pti['iso3'].isin(oecd_iso_set)]
        afford = pd.concat([oecd_df, bis_extra], ignore_index=True)

        # ----- TFR -----
        tfr_rows = []
        for iso3 in afford['iso3'].unique():
            t0 = get_tfr(tfr_long, iso3, base_year)
            t1 = get_tfr(tfr_long, iso3, END_YEAR)
            if not (np.isnan(t0) or np.isnan(t1)):
                tfr_rows.append({'iso3': iso3, 'dtfr': t1 - t0})
        tfr_df = pd.DataFrame(tfr_rows)

        merged = afford.merge(tfr_df, on='iso3').dropna()
        if len(merged) < 10:
            continue

        for sample in samples:
            sub = merged.copy()
            if sample == 'oecd_only':
                sub = sub[sub['src'] == 'OECD']
            elif sample == 'drop_cee':
                sub = sub[~sub['iso3'].isin(CEE)]

            if len(sub) < 10:
                continue

            x, y = sub['dpti'].values, sub['dtfr'].values
            slope, intercept, r, p, _ = stats.linregress(x, y)

            # Hungary residual (positive = above the line)
            hun = sub[sub['iso3'] == 'HUN']
            hun_resid = np.nan
            if not hun.empty:
                hun_pred  = intercept + slope * hun['dpti'].iloc[0]
                hun_resid = hun['dtfr'].iloc[0] - hun_pred

            results.append({
                'measure':    measure,
                'base_year':  base_year,
                'sample':     sample,
                'n':          len(sub),
                'slope':      round(slope, 5),
                'r':          round(r, 3),
                'p':          round(p, 4),
                'hun_resid':  round(hun_resid, 3) if not np.isnan(hun_resid) else np.nan,
            })

# ---------------------------------------------------------------------------
# 6. Report
# ---------------------------------------------------------------------------
res = pd.DataFrame(results).sort_values('slope')

print('\n=== TOP 20 SPECIFICATIONS BY MOST NEGATIVE SLOPE ===\n')
pd.set_option('display.max_colwidth', 40)
pd.set_option('display.width', 120)
print(res.head(20).to_string(index=False))

print('\n=== FILTERED: Hungary above trend (resid > 0.05) ===\n')
pos = res[res['hun_resid'] > 0.05].head(20)
print(pos.to_string(index=False))
