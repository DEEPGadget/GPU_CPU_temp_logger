import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
import argparse


def plot_gpu_temp(csv_path, title):
    # Read the CSV file
    df = pd.read_csv('temperature_data.csv')

    # Convert the Timestamp column to datetime
    df['Timestamp'] = pd.to_datetime(df['Timestamp'])
    
    gpu_columns = [col for col in df.columns if 'GPU' in col]
    fig = px.line(df, x='Timestamp', y=gpu_columns, labels={'value': 'Chipset temperature (°C)'})
    
    for gpu in gpu_columns:
        max_value = df[gpu].max()
        max_time = df[df[gpu] == max_value]['Timestamp'].iloc[0]
        fig.add_trace(go.Scatter(
            x=[max_time], y=[max_value],
            mode='markers+text',
            name=f'{gpu} max',
            text=[f'{max_value}°C'],
            showlegend=False,
            marker=dict(size=10, color='red')
        ))

    # Create a figure
    #fig = px.line(df, x='Timestamp', y=[' GPU0_Temperature',' GPU1_Temperature',' GPU2_Temperature',' GPU3_Temperature',' GPU4_Temperature',' GPU5_Temperature',' GPU6_Temperature',' GPU7_Temperature'], labels={'value': 'Temperature (°C)', 'Timestamp': 'Time'}, title='GPU Temperatures Over Time')
    #fig.add_annotation(


    # Update the layout for better readability
    fig.update_layout(title=title,
                      xaxis_title='Timestamp(measurement per 5 seconds)',
                      yaxis_title='Chipset temperature (°C)',
                      yaxis_range=[0,100],
                      legend_title_text='GPUs',
                      legend=dict(orientation="h",
                                  yanchor="bottom",
                                  y=1.02,
                                  xanchor="right",
                                  x=1))

    # Save the figure as an image file
    fig.write_image("gpu_temperatures_over_time.png")

    # Show the plot
    fig.show()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Plot GPU temperature over time from a CSV file')
    parser.add_argument('file_path', type=str, help='Path to the CSV file.')
    parser.add_argument('title', type=str, help='Title of the graph.')

    args = parser.parse_args()
    plot_gpu_temp(args.file_path, args.title)
