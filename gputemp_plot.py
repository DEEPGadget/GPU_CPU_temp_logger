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
#add
for _ in pattern.finditer(filelst):# matching keyword iteration 
    print(_.group())
    file = dir + '/' + str(_.group())
    print("file", file)
    df = pd.read_csv(file, index_col=None, header = 0)
    df.columns = ['Timestamp(sec.)', 'GPU'+str(count), 'BUSID', 'NAME']

    if count is 1: 
        global concat_df 
        concat_df = df = df.drop(df.columns[[2,3]], axis=1)
        global fig
        fig = concat_df.plot(kind='line',
                             x='Timestamp(sec.)',
                             y='GPU'+str(count), 
                             title='DG5W-4090-6 Burning Test (48hr.)')
    else:
        concat_df = concat_df.join(df['GPU'+str(count)])
        print(concat_df)
        fig.add_scatter(x=concat_df['Timestamp(sec.)'], 
                        y=concat_df['GPU'+str(count)], 
                        mode='lines', 
                        name='gpu'+str(count))
    df_deldup = concat_df.drop_duplicates(['GPU'+str(count)], keep = 'first', ignore_index = True)
    peak_val_y = df_deldup['GPU'+str(count)].max()
    peak_val_x = df_deldup[df_deldup['GPU'+str(count)] == peak_val_y]['Timestamp(sec.)'].values[0]
    fig.add_annotation(x=peak_val_x, 
                       y=peak_val_y,
                       text='GPU '+str(count)+'peak: ' + str(peak_val_y)+'°C',
                       showarrow=True,
                       arrowhead=1,
                       ay = random.randint(-45,-20))
    count += 1
print("concat_df", concat_df)
fig.update_layout(font_family="Arial",
                  font_color ="black",
                  title=dict(text='<b>DG5W-4090-6 Burning Test (48hr.)</b>',
                             font=dict(family = "Arial",
                             size=25,
                             color='#000000'),
                             x = 0.5,
                             y = 0.94,
                             xanchor = "center",
                             yanchor = "middle"),
                  xaxis_title='<b>Timestamp(sec.)</b>',
                  yaxis_title='<b>GPU Chipset Temperature(°C)',
                  font=dict(family="Arial",
                            size=18,
                            color="black"))

fig.update_xaxes(ticks="inside",
                 tickwidth=2,
                 title_font = {"size":20})

fig.update_yaxes(range=[0, 100],
                 ticks="inside",
                 tickwidth=2,
                 title_font = {"size":20})
fig.show()


    



