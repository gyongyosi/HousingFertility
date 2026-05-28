"""
Downloads and assembles cross-country housing affordability and TFR data.

Specification: OECD only, PTI measure, 2010–2019 period
(highest correlation with TFR change among alternative specifications)

Affordability source:
  OECD Analytical House Price Indicators – price-to-income ratio (PTI),
  % of long-run average.  Source: OECD.ECO.MPD / DF_HOUSE_PRICES

TFR source: World Bank WDI (SP.DYN.TFRT.IN)

Period: 2010 → 2019  (change in PTI and TFR)

Output: data/cross_country/cross_country_affordability.csv
Figure: produced by 205_cross_country_figure.do
"""

import os, io, requests
import pandas as pd
import numpy as np

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
ROOT     = '/home/gyozo/Dropbox/claude/research/HousingFertility'
DATA_RAW = os.path.join(ROOT, 'data', 'cross_country')
TFR_CSV  = os.path.join(ROOT, 'data', 'human_fertility',
                        'API_SP.DYN.TFRT.IN_DS2_en_csv_v2_252787.csv')
CSV_OUT  = os.path.join(DATA_RAW, 'cross_country_affordability.csv')

os.makedirs(DATA_RAW, exist_ok=True)

OECD_FILE = os.path.join(DATA_RAW, 'oecd_house_prices.csv')
BIS_FILE  = os.path.join(DATA_RAW, 'WS_SPP_csv_flat.csv')
GDP_FILE  = os.path.join(DATA_RAW, 'wb_gdppc_real.csv')

BASE_YEAR = 2010
END_YEAR  = 2019

# ---------------------------------------------------------------------------
# 1. OECD price-to-income ratio
# ---------------------------------------------------------------------------
if not os.path.exists(OECD_FILE):
    print('Downloading OECD house price indicators...')
    url = ('https://sdmx.oecd.org/public/rest/data/'
           'OECD.ECO.MPD,DSD_AN_HOUSE_PRICES@DF_HOUSE_PRICES,1.0/'
           '?format=csvfilewithlabels&startPeriod=2005&endPeriod=2022')
    r = requests.get(url, timeout=120)
    r.raise_for_status()
    with open(OECD_FILE, 'w', encoding='utf-8') as f:
        f.write(r.text)
    print(f'  saved {OECD_FILE}')

oecd = pd.read_csv(OECD_FILE)
oecd_pti = oecd[(oecd['Measure'] == 'Price to income ratio') &
                (oecd['FREQ'] == 'A')].copy()
oecd_pti['year'] = pd.to_numeric(oecd_pti['TIME_PERIOD'], errors='coerce')
oecd_pti['pti']  = pd.to_numeric(oecd_pti['OBS_VALUE'],  errors='coerce')
oecd_pti = oecd_pti[['Reference area', 'year', 'pti']].dropna()

agg_names = {'Euro area', 'Euro area (17 countries)', 'Euro area (19 countries)',
             'Euro area (20 countries)', 'OECD', 'G7', 'G20', 'OECD - Total'}
oecd_pti = oecd_pti[~oecd_pti['Reference area'].isin(agg_names)]

def nearest_year(df, country_col, value_col, year_col, country, year, tol=1):
    sub = df[df[country_col] == country].dropna(subset=[value_col])
    exact = sub[sub[year_col] == year]
    if not exact.empty:
        return exact[value_col].iloc[0]
    near = sub.iloc[(sub[year_col] - year).abs().argsort().iloc[:1]]
    if not near.empty and abs(near[year_col].iloc[0] - year) <= tol:
        return near[value_col].iloc[0]
    return np.nan

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

oecd_rows = []
for country in oecd_pti['Reference area'].unique():
    v0 = nearest_year(oecd_pti, 'Reference area', 'pti', 'year', country, BASE_YEAR)
    v1 = nearest_year(oecd_pti, 'Reference area', 'pti', 'year', country, END_YEAR)
    if not (np.isnan(v0) or np.isnan(v1)):
        oecd_rows.append({'country': country,
                          'dpti':    v1 - v0,
                          'source':  'OECD'})
oecd_change = pd.DataFrame(oecd_rows)
oecd_change['iso3'] = oecd_change['country'].map(oecd_iso3)
oecd_change = oecd_change.dropna(subset=['iso3'])
print(f'OECD PTI: {len(oecd_change)} countries')

# ---------------------------------------------------------------------------
# 2. BIS real residential property prices  (2010 = 100)
# ---------------------------------------------------------------------------
if not os.path.exists(BIS_FILE):
    print('Downloading BIS WS_SPP...')
    import zipfile
    r = requests.get('https://data.bis.org/static/bulk/WS_SPP_csv_flat.zip',
                     headers={'User-Agent': 'Mozilla/5.0'}, timeout=120)
    r.raise_for_status()
    z = zipfile.ZipFile(io.BytesIO(r.content))
    z.extractall(DATA_RAW)
    print(f'  saved {BIS_FILE}')

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
              .mean()
              .reset_index()
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

bis_0 = bis_annual[bis_annual['year'] == BASE_YEAR].set_index('iso3')['rhpi']
bis_1 = bis_annual[bis_annual['year'] == END_YEAR].set_index('iso3')['rhpi']
bis_hp_chg = ((bis_1 - bis_0) / bis_0 * 100).dropna().reset_index()
bis_hp_chg.columns = ['iso3', 'drhpi']

# ---------------------------------------------------------------------------
# 3. World Bank real GDP per capita  (constant 2015 USD)
# ---------------------------------------------------------------------------
if not os.path.exists(GDP_FILE):
    print('Downloading World Bank real GDP per capita...')
    frames = []
    for yr in [BASE_YEAR, END_YEAR]:
        url2 = ('https://api.worldbank.org/v2/country/all/indicator/NY.GDP.PCAP.KD'
                f'?format=json&date={yr}&per_page=500')
        for attempt in range(3):
            try:
                r2 = requests.get(url2, timeout=90)
                data = r2.json()
                recs = data[1] if len(data) > 1 else []
                frames.append(pd.DataFrame([
                    {'iso3': rec['countryiso3code'],
                     'year': int(rec['date']),
                     'gdppc': rec['value']}
                    for rec in recs if rec.get('value') is not None
                ]))
                print(f'  {yr}: {len(frames[-1])} countries')
                break
            except Exception as e:
                print(f'  {yr} attempt {attempt+1} failed: {e}')
    gdp_long = pd.concat(frames, ignore_index=True)
    gdp_long.to_csv(GDP_FILE, index=False)
else:
    gdp_long = pd.read_csv(GDP_FILE)

gdp_0   = gdp_long[gdp_long['year'] == BASE_YEAR].set_index('iso3')['gdppc']
gdp_1   = gdp_long[gdp_long['year'] == END_YEAR].set_index('iso3')['gdppc']
gdp_chg = ((gdp_1 - gdp_0) / gdp_0 * 100).reset_index()
gdp_chg.columns = ['iso3', 'dgdppc']

# Real PTI proxy change = real HP change − real income change (in pp)
bis_pti = (bis_hp_chg.set_index('iso3')
           .join(gdp_chg.set_index('iso3'), how='inner'))
bis_pti['dpti'] = bis_pti['drhpi'] - bis_pti['dgdppc']
bis_pti = bis_pti[['dpti']].dropna().reset_index()
bis_pti['source'] = 'BIS+WB'
print(f'BIS PTI proxy: {len(bis_pti)} countries')

# ---------------------------------------------------------------------------
# 4. OECD only (no BIS+WB)
# ---------------------------------------------------------------------------
afford = oecd_change[['iso3', 'dpti', 'source']].copy()

# ---------------------------------------------------------------------------
# 5. World Bank TFR
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
        .apply(get_tfr, yr=END_YEAR,  include_groups=False)
        .reset_index(name='tfr1'))
tfr_chg = (tfr0.merge(tfr1, on='Country Code')
               .assign(dtfr=lambda x: x['tfr1'] - x['tfr0'])
               [['Country Code', 'dtfr']]
               .rename(columns={'Country Code': 'iso3'}))

# ---------------------------------------------------------------------------
# 6. Final merge and save
# ---------------------------------------------------------------------------
iso3_names = {
    'AUS': 'Australia',     'AUT': 'Austria',      'BEL': 'Belgium',
    'BGR': 'Bulgaria',      'BRA': 'Brazil',        'CAN': 'Canada',
    'CHE': 'Switzerland',   'CHL': 'Chile',         'CHN': 'China',
    'COL': 'Colombia',      'CRI': 'Costa Rica',    'CYP': 'Cyprus',
    'CZE': 'Czech Rep.',    'DEU': 'Germany',       'DNK': 'Denmark',
    'EST': 'Estonia',       'ESP': 'Spain',         'FIN': 'Finland',
    'FRA': 'France',        'GBR': 'United Kingdom','GRC': 'Greece',
    'HKG': 'Hong Kong',     'HRV': 'Croatia',       'HUN': 'Hungary',
    'IDN': 'Indonesia',     'IND': 'India',         'IRL': 'Ireland',
    'ISL': 'Iceland',       'ISR': 'Israel',        'ITA': 'Italy',
    'JPN': 'Japan',         'KOR': 'S. Korea',      'LTU': 'Lithuania',
    'LUX': 'Luxembourg',    'LVA': 'Latvia',        'MAR': 'Morocco',
    'MEX': 'Mexico',        'MKD': 'N. Macedonia',  'MLT': 'Malta',
    'MYS': 'Malaysia',      'NLD': 'Netherlands',   'NOR': 'Norway',
    'NZL': 'New Zealand',   'PER': 'Peru',          'PHL': 'Philippines',
    'POL': 'Poland',        'PRT': 'Portugal',      'ROU': 'Romania',
    'RUS': 'Russia',        'SGP': 'Singapore',     'SVK': 'Slovakia',
    'SVN': 'Slovenia',      'SRB': 'Serbia',        'SWE': 'Sweden',
    'THA': 'Thailand',      'TUR': 'Turkey',        'USA': 'United States',
    'ZAF': 'South Africa',
}

df = (afford.merge(tfr_chg, on='iso3')
            .dropna()
            .assign(label=lambda x: x['iso3'].map(iso3_names).fillna(x['iso3'])))
df = df[['iso3', 'label', 'dpti', 'dtfr', 'source']]

df.to_csv(CSV_OUT, index=False)

print(f'\nSaved {len(df)} countries to {CSV_OUT}')
print(df.sort_values('dpti')[['label', 'dpti', 'dtfr', 'source']].to_string(index=False))
