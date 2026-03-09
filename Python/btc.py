import pandas as pd
import yfinance as yf
import requests

# Get Fear & Greed index
url = requests.get('https://api.alternative.me/fng/?limit=0')
data = url.json()['data']
df = pd.DataFrame(data)
df.info()

# %% Change data types
df.dtypes
df['timestamp'] = pd.to_numeric(df['timestamp'])
df['timestamp'] = pd.to_datetime(df['timestamp'], unit = 's')
df['value'] = df['value'].astype(int)
df.info()

# %% Trip data to start from the right date
df = df[df['timestamp'] <= '2026-02-18']
df.head()

# %% Get prices for BTC
btc_finance = yf.download('BTC-USD', start = '2018-02-05', end = '2026-02-18')
btc = btc_finance.reset_index()
btc.tail()

# %% Leave neccesary columns
btc.columns = ['Date', 'Close', 'High', 'Low', 'Open', 'Volume']
btc.head()

# %% Merge data into a single DataFrame
df_final = pd.merge(df, btc, left_on = 'timestamp', right_on = 'Date')
pd.set_option('display.max_columns', None)
df_final.head()

# %% Remove unnecessary columns
df_final = df_final.drop(columns = ['time_until_update', 'Date'])

# %% Save final file
df_final.to_excel(r'C:\Users\PC\Desktop\google trends\btc_analysis.xlsx', index=False)

