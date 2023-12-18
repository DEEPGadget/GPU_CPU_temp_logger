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

dir = '/home/deepgadget/GPU_CPU_temp_logger'
pattern = re.compile('gpu_\d.csv')
filelst =  str(os.listdir(dir))# generate filname list and casting to single string 
count = 1
label_arrow = [-75, -65, -55, -35, 35, 55, 75]
rnd_list = random.sample(range(0,8),8)

for _ in pattern.finditer(filelst):# matching keyword iteration 
    print(_.group())
    file = dir + '/' + str(_.group())
    print("file", file)
    df = pd.read_csv(file, index_col=None, header = 0)
    df.columns = ['Timestamp(sec.)', 'GPU'+str(count), 'BUSID', 'NAME']

    if count == 1: 
        global concat_df 
        concat_df = df = df.drop(df.columns[[2,3]], axis=1)
        global fig
        fig = concat_df.plot(kind='line',
                             x='Timestamp(sec.)',
                             y='GPU'+str(count), 
                             title='DG5W-4090-6 Burning Test (48hr.)')
    else:
        print(concat_df)
        concat_df = concat_df.join(df['GPU'+str(count)])
    fig.add_scatter(x=concat_df['Timestamp(sec.)'],
                    y=concat_df['GPU'+str(count)], 
                    mode='lines', 
                    name='GPU'+str(count))
    print(concat_df)
    df_deldup = concat_df.drop_duplicates(['GPU'+str(count)], keep = 'first', ignore_index = True)
    peak_val_y = df_deldup['GPU'+str(count)].max()
    peak_val_x = df_deldup[df_deldup['GPU'+str(count)] == peak_val_y]['Timestamp(sec.)'].values[0]
    fig.add_annotation(x=peak_val_x, 
                       y=peak_val_y,
                       font=dict(family="Courier New, monospace", size=13, color="black"),
                       align = "center",
                       arrowwidth=2,
                       arrowcolor="#636363",
                       text='<b>GPU'+str(count)+' peak:' + str(peak_val_y)+'°C</b>',
                       showarrow=True,
                       arrowhead=1,
                       ay = label_arrow[rnd_list[count]]) 
    count += 1


print("concat_df", concat_df)

fig.update_xaxes(#ticks="inside",
                 tickwidth=2,
                 title_font = {"size":20},
                 automargin = True,
                 #tickangle=30,
                 minor=dict(ticklen=2, tickcolor="black"))#,showgrid=True))

fig.update_yaxes(range=[0, 100],
                 ticks="inside",
                 tickwidth=2,
                 title_font = {"size":20})
#fig.show()
fig.update_layout(font_family="Arial",
                  font_color ="black",
                  width=1600,
                  height=700,
                  title=dict(text='<b>DG5W-4090-4 Burning Test (48hr., FAN:67)</b>',
                             font=dict(family = "Arial",
                             size=25,
                             color='#000000'),
                             x = 0.5,
                             y = 0.94,
                             xanchor = "center",
                             yanchor = "middle"),
                  xaxis_title='<b>Timestamp(sec.)</b>',
                  yaxis_title='<b>GPU Chipset Temperature(°C)',
                  legend=dict(orientation="h",
                              yanchor="bottom",
                              y=1.02,
                              xanchor="right",
                              borderwidth=1,
                              x=1),
                  font=dict(family="Arial",
                            size=18,
                            color="black"))


fig.write_image("output.png")