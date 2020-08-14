#!/usr/bin/env python
# coding: utf-8

# ## Step-by-step guide to generating an interactive climate map in Bokeh (& Geopandas)
#
# - **With some specific boilerplate code already filled in.**
#

# - **CREDITS**:
#
#     - The idea / code for this lesson was heavily inspired by the following tutorial:
#         - [A Complete Guide to an Interactive Geographical Map using Python](https://towardsdatascience.com/a-complete-guide-to-an-interactive-geographical-map-using-python-f4c5197e23e0), by [Shivangi Patel](https://github.com/CrazyDaffodils).
#
#     - The tutorial was adapted / re-written by [Paul Wlodkowski](https://github.com/pawlodkowski) for the *Plotting on Maps* lesson @ Spiced Academy.
#         - The data for this particular lesson was scraped from [Berkeley Earth](http://berkeleyearth.lbl.gov/country-list/) and cleaned / pre-processed ahead of time.

# In[1]:


import pandas as pd
import geopandas as gpd

from bokeh.plotting import figure
from bokeh.io import output_notebook, show
from bokeh.models import GeoJSONDataSource
from bokeh.palettes import brewer
from bokeh.models import LinearColorMapper
from bokeh.models import ColorBar, HoverTool
from bokeh.models import Slider
from bokeh.layouts import widgetbox, column
from bokeh.io import curdoc


DATA = '../bokeh/all_years.csv'

df = pd.read_csv(DATA)

df = df.loc[df['country'] != 'Antarctica']


df.head(2)




SHAPEFILE = '../data/ne_110m_admin_0_countries.shp'


gdf = gpd.read_file(SHAPEFILE)[['ADMIN', 'geometry']] # select columns 'geometry: coordinates of each country'

df = df.groupby(['country', 'year'])[['monthly_anomaly']].mean().reset_index() ## double [[]] for monthly_anomaly to get a pdDataFrame back and not a list


# ### STEP 4: Merge Data Sets.
# - We want to have our temperature data and geometric data in one place.
# - Make sure you're still left with a GeoDataFrame at the end. # put in the gdf as left for merge!!!

gdf_merged = pd.merge(left = gdf, right = df, left_on = 'ADMIN', right_on = 'country')

gdf_merged.tail()


#    ### 5a. Generate a blank canvas / figure.

# ### 5b. Generate a GeoJSON for a single year and use it to add shapes onto the figure
# - Let's use the year 2000 as an example.
# - **Programming Tip**:
#     - If we can write code to work for a single year (hardcoded), then we can generalize this later to work for *any*  year!

gdf_2000 = gdf_merged[gdf_merged['year'] == 2019]
json_2000 = gdf_2000.to_json()


gdf_2000.head()

gdf_merged.head()

gdf_merged['monthly_anomaly'].min()

def get_geojson(yr):
    """Input a year (int) and return corresponding GeoJSON"""
    gdf_year = gdf_merged[gdf_merged['year'] == yr]
    return gdf_year.to_json()
geosource = GeoJSONDataSource(geojson = get_geojson(2019))


geosource = GeoJSONDataSource(geojson = json_2000)


# In[18]:


hover = HoverTool(tooltips = [ ('Country','@country'), ('Temp. Anomaly', '@monthly_anomaly')])


# In[19]:


slider = Slider(title = 'Year', start = 1900, end = 2032, step = 1, value = 2013)
#define the constraints of the year slider


# In[20]:


p = figure(title = 'Avg. Monthly Temperature Anomaly for Year 1900',
           plot_height = 600,
           plot_width = 900,
           tools=[hover]
          )


# In[21]:


p.tools.append(hover)


# In[22]:


palette = brewer['RdBu'][11]


# In[23]:


color_mapper = LinearColorMapper(palette = palette,
                                 low = -3.5,
                                 high = 3.5,
                                 nan_color = 'cornflowerblue')


# In[24]:


color_bar = ColorBar(color_mapper = color_mapper,
                     label_standoff = 8,
                     width =  500,
                     height = 20,
                     location = (0,0),
                     orientation = 'horizontal'
                    )


# In[25]:


p.patches('xs',
          'ys',
          source = geosource,
          fill_color = {'field' :'monthly_anomaly', 'transform': color_mapper}, ### NEW ###
          line_color = 'blue',
          line_width = 1)


# In[26]:


p.add_layout(color_bar, 'below')


# In[27]:


show(p)


# In[28]:


def update_plot(attr, old, new):

    """Change properties / attributes of the datasource and title depending on slider value / position."""

    yr = slider.value
    new_data = get_geojson(yr) #our custom function from before
    geosource.geojson = new_data
    p.title.text = f'Avg. Monthly Temperature Anomaly for Year {yr}'



# In[29]:


slider.on_change('value', update_plot)


# In[30]:


layout = column(p,widgetbox(slider))
curdoc().add_root(layout)


# **To view this application in interactive mode you need to set up a local Bokeh server.**
#
# **In the terminal, run:**
#
# ``bokeh serve --show <name_of_notebook>.ipynb``

# **More Hints**:
# - If you're having trouble getting your interactive map working properly, **try exporting your Jupyter Notebook code to a python script.**
#     - Clean up your code, remove unnecessary lines, get rid of comments / markdown!
#     - Afterwards you can run the bokeh server from the python script:
#         - `bokeh serve --show <name_of_script>.py`

# In[ ]:
