
import matplotlib.pyplot as plt 
import pandas as pd
pd.options.plotting.backend = 'plotly'
import os 
import re
import matplotlib.dates as md
import numpy as np
import plotly.express as px 
import plotly.graph_objects as go
import random
from plotly.subplots import make_subplots
import sys

dir = '/home/irlab/GPU_CPU_temp_logger'
pattern = re.compile('gpu_\d.csv')
filelst =  str(os.listdir(dir))# generate filname list and casting to single string 
count = 1

for _ in pattern.finditer(filelst):# matching keyword iteration 
    print(_.group())
    file = dir + '/' + str(_.group())
    print("file", file)
    df = pd.read_csv(file, index_col=None, header = 0)
    df.columns = ['Timestamp(sec.)', 'GPU'+str(count), 'BUSID', 'NAME']

    if count == 1: 
        global concat_df 
        concat_df = df.drop(df.columns[[2,3]], axis=1)
    else:
        print(concat_df)
        concat_df = concat_df.join(df['GPU'+str(count)])
    count += 1

print(concat_df)
concat_df['Timestamp(sec.)'] = concat_df['Timestamp(sec.)'].str[2:19]
fig = make_subplots(rows=count-1, cols=1,
                    x_title = '<b>Timestamp(sec.)</b>',
                    y_title = '<b>GPU Chipset Temperature(°C)</b>')

#                    x_title=dict(text='<b>Timestamp(sec.)</b>',
#                                 font=dict(family = "Arial",
#                                 size=23)),                            
#                    y_title=dict(text='<b>GPU Chipset Temperature(°C)</b>',
#                                 font=dict(family = "Arial",
#                                 size=23)))
 
for i in range(1,count):
    deldup_df = concat_df.drop_duplicates(['GPU'+str(i)], keep = 'first',ignore_index = True)
    peak_val_y = deldup_df['GPU'+str(i)].max()
    peak_val_x = deldup_df[deldup_df['GPU'+str(i)] == peak_val_y]['Timestamp(sec.)'].values[0]
    fig.append_trace(go.Scatter(
            x=concat_df['Timestamp(sec.)'].values,
            y=concat_df['GPU'+ str(i)],
            name='GPU '+str(i)),
            row=i, col=1)
    fig.add_annotation(x=peak_val_x,
                       y=peak_val_y,
                       font=dict(family="Courier New, monospace", size=13, color="black"),
                       align = "center",
                       arrowwidth=2,
                       arrowcolor="#636363",
                       text='<b>GPU'+str(i)+' peak:' + str(peak_val_y)+'°C</b>',
                       showarrow=True,
                       arrowhead=1,
                       ay = -35,
                       row=i,
                       col=1)

fig.update_yaxes(range=[0, 100],
                 ticks="inside",
                 tickwidth=2,
                 title_font = {"size":10})
fig.update_xaxes(ticks="inside",
                 tickwidth=2,
                 title_font = {"size":10})


fig.update_layout(height=700,
                  width=1400, 
                  title=dict(text='<b>'+str(sys.argv[1])+' Burning Test ' + '(' + str(sys.argv[2]) + 'hours)' + '</b>',
                              font=dict(family = "Arial",
                              size=25,
                              color='#000000'),
                             x = 0.5,
                             y = 0.94,
                             xanchor = "center",
                             yanchor = "middle"),
                 legend=dict(orientation="h", 
                              yanchor="bottom",
                              y=1.02,
                              xanchor="right",
                              borderwidth=1,
                              x=1),
                  xaxis = dict(tickfont = dict(size=12)))
                  #font=dict(family="Arial",
                  #          size=18,
                  #          color="black"))
fig.write_image("output.png")
