"""
Cross-country housing affordability and TFR change, 2010–2019.
Sources: OECD price-to-income ratio, World Bank TFR.
Output: data/cross_country/cross_country_affordability.csv
"""

import os
import requests
import pandas as pd
import numpy as np

ROOT     = '/home/gyozo/Dropbox/_babavaro'
DATA_RAW = os.path.join(ROOT, 'data', 'cross_country')
OECD_FILE = os.path.join(DATA_RAW, 'oecd_house_prices.csv')
TFR_CSV  = os.path.join(ROOT, 'data', 'human_fertility',
                        'API_SP.DYN.TFRT.IN_DS2_en_csv_v2_252787.csv')
CSV_OUT  = os.path.join(DATA_RAW, 'cross_country_affordability.csv')

os.makedirs(DATA_RAW, exist_ok=True)

BASE_YEAR = 2010
END_YEAR  = 2019

# Download OECD price-to-income ratio
if not os.path.exists(OECD_FILE):
    print('Downloading OECD PTI...')
    url = ('https://sdmx.oecd.org/public/rest/data/'
           'OECD.ECO.MPD,DSD_AN_HOUSE_PRICES@DF_HOUSE_PRICES,1.0/'
           '?format=csvfilewithlabels&startPeriod=2005&endPeriod=2022')
    r = requests.get(url, timeout=120)
    r.raise_for_status()
    with open(OECD_FILE, 'w', encoding='utf-8') as f:
        f.write(r.text)

oecd = pd.read_csv(OECD_FILE)
oecd_pti = oecd[(oecd['Measure'] == 'Price to income ratio') &
                (oecd['FREQ'] == 'A')].copy()
oecd_pti['year'] = pd.to_numeric(oecd_pti['TIME_PERIOD'], errors='coerce')
oecd_pti['pti']  = pd.to_numeric(oecd_pti['OBS_VALUE'], errors='coerce')
oecd_pti = oecd_pti[['Reference area', 'year', 'pti']].dropna()

agg = {'Euro area', 'Euro area (17 countries)', 'Euro area (19 countries)',
       'Euro area (20 countries)', 'OECD', 'G7', 'G20', 'OECD - Total'}
oecd_pti = oecd_pti[~oecd_pti['Reference area'].isin(agg)]

def get_value(df, country, year, tol=1):
    sub = df[df['Reference area'] == country].dropna(subset=['pti'])
    exact = sub[sub['year'] == year]
    if not exact.empty:
        return exact['pti'].iloc[0]
    near = sub.iloc[(sub['year'] - year).abs().argsort()[:1]]
    if not near.empty and abs(near['year'].iloc[0] - year) <= tol:
        return near['pti'].iloc[0]
    return np.nan

iso3_map = {
    'Australia': 'AUS', 'Austria': 'AUT', 'Belgium': 'BEL', 'Bulgaria': 'BGR',
    'Canada': 'CAN', 'Chile': 'CHL', 'Colombia': 'COL', 'Costa Rica': 'CRI',
    'Croatia': 'HRV', 'Czechia': 'CZE', 'Denmark': 'DNK', 'Estonia': 'EST',
    'Finland': 'FIN', 'France': 'FRA', 'Germany': 'DEU', 'Greece': 'GRC',
    'Hungary': 'HUN', 'Iceland': 'ISL', 'Ireland': 'IRL', 'Israel': 'ISR',
    'Italy': 'ITA', 'Japan': 'JPN', 'Korea': 'KOR', 'Latvia': 'LVA',
    'Lithuania': 'LTU', 'Luxembourg': 'LUX', 'Netherlands': 'NLD',
    'New Zealand': 'NZL', 'Norway': 'NOR', 'Poland': 'POL', 'Portugal': 'PRT',
    'Romania': 'ROU', 'Russia': 'RUS', 'Slovak Republic': 'SVK',
    'Slovenia': 'SVN', 'South Africa': 'ZAF', 'Spain': 'ESP', 'Sweden': 'SWE',
    'Switzerland': 'CHE', 'United Kingdom': 'GBR', 'United States': 'USA',
    "China (People's Republic of)": 'CHN', 'Brazil': 'BRA',
}

afford = []
for country in oecd_pti['Reference area'].unique():
    v0 = get_value(oecd_pti, country, BASE_YEAR)
    v1 = get_value(oecd_pti, country, END_YEAR)
    if not (np.isnan(v0) or np.isnan(v1)):
        iso3 = iso3_map.get(country)
        if iso3:
            afford.append({'iso3': iso3, 'dpti': v1 - v0})

afford = pd.DataFrame(afford)
print(f'Countries with PTI data: {len(afford)}')

# World Bank TFR
tfr_raw = pd.read_csv(TFR_CSV, skiprows=4, encoding='utf-8-sig')
tfr_raw = tfr_raw.loc[:, ~tfr_raw.columns.str.startswith('Unnamed')]
id_cols  = ['Country Name', 'Country Code', 'Indicator Name', 'Indicator Code']
tfr_long = tfr_raw.melt(
    id_vars=id_cols,
    value_vars=[c for c in tfr_raw.columns if c not in id_cols],
    var_name='year', value_name='tfr')
tfr_long['year'] = pd.to_numeric(tfr_long['year'], errors='coerce').astype('Int64')
tfr_long = tfr_long.dropna(subset=['tfr'])

def get_tfr(group, yr, tol=1):
    sub = group.dropna(subset=['tfr'])
    if sub.empty: return np.nan
    exact = sub[sub['year'] == yr]
    if not exact.empty: return float(exact['tfr'].iloc[0])
    near = sub.iloc[(sub['year'] - yr).abs().argsort()[:1]]
    return float(near['tfr'].iloc[0]) if abs(int(near['year'].iloc[0]) - yr) <= tol else np.nan

tfr0 = (tfr_long.groupby('Country Code')
        .apply(get_tfr, yr=BASE_YEAR, include_groups=False)
        .reset_index(name='tfr0'))
tfr1 = (tfr_long.groupby('Country Code')
        .apply(get_tfr, yr=END_YEAR, include_groups=False)
        .reset_index(name='tfr1'))
tfr_chg = (tfr0.merge(tfr1, on='Country Code')
               .assign(dtfr=lambda x: x['tfr1'] - x['tfr0'])
               [['Country Code', 'dtfr']]
               .rename(columns={'Country Code': 'iso3'}))

print(f'Countries with TFR data: {len(tfr_chg)}')

# Merge affordability and fertility
iso3_names = {
    'AUS': 'Australia',     'AUT': 'Austria',      'BEL': 'Belgium',
    'BGR': 'Bulgaria',      'BRA': 'Brazil',        'CAN': 'Canada',
    'CHE': 'Switzerland',   'CHL': 'Chile',         'CHN': 'China',
    'COL': 'Colombia',      'CRI': 'Costa Rica',    'CZE': 'Czech Rep.',
    'DEU': 'Germany',       'DNK': 'Denmark',       'EST': 'Estonia',
    'ESP': 'Spain',         'FIN': 'Finland',       'FRA': 'France',
    'GBR': 'United Kingdom', 'GRC': 'Greece',      'HRV': 'Croatia',
    'HUN': 'Hungary',       'IRL': 'Ireland',       'ISL': 'Iceland',
    'ISR': 'Israel',        'ITA': 'Italy',         'JPN': 'Japan',
    'KOR': 'S. Korea',      'LTU': 'Lithuania',     'LUX': 'Luxembourg',
    'LVA': 'Latvia',        'NLD': 'Netherlands',   'NOR': 'Norway',
    'NZL': 'New Zealand',   'POL': 'Poland',        'PRT': 'Portugal',
    'ROU': 'Romania',       'RUS': 'Russia',        'SVK': 'Slovakia',
    'SVN': 'Slovenia',      'SWE': 'Sweden',        'USA': 'United States',
    'ZAF': 'South Africa',
}

df = (afford.merge(tfr_chg, on='iso3')
           .dropna()
           .assign(label=lambda x: x['iso3'].map(iso3_names).fillna(x['iso3'])))
df = df[['iso3', 'label', 'dpti', 'dtfr']]

df.to_csv(CSV_OUT, index=False)
print(f'Saved {len(df)} countries to {CSV_OUT}')
