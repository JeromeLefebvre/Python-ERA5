import xarray as xr
import pandas as pd
import pyarrow # required for to_parquet method
import fastparquet # required for to_parquet method

# Load the dataset
ds = xr.open_dataset('NC/era5_australia_2001.nc')

df = ds.to_dataframe()
df.to_parquet('Parquet/era5_australia_2001.parquet')

