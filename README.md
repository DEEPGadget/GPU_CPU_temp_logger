# System_temperature_logger

Simple shell script and automatic visualizer for logging your system temperature.   
```temp_logger.sh``` is record the Storages, CPUs, GPUs, and memory usage for dedicated time.
Then generate ```thermo_data.csv``` file in exist path.   
```plot.py``` is visualize the GPUs temperature by using ``thermo_data.csv``. It generate linear thermo graph for GPUs.

## Getting Started

### Dependencies

* Ubuntu 20.04 or higher
* NVIDIA driver 550 or higher
* CUDA 12.1 or higher(for gpu-burn)
* [```gpu-burn```](https://github.com/wilicc/gpu-burn) (GPU stress tool, there is no essential connection to run)
* [```stress```](https://howtoinstall.co/package/stress) (CPU stress tool, there is no essential connection to run)
* ```lm-sensors```
* ```fio``` (Storage stress tool, there is no essential connection to run)
* ```nvme-cli```
* pip packages
  * plotly pandas

### Install
```
# Install dependency packages above.
git clone https://github.com/DEEPGadget/GPU_CPU_temp_logger.git
cd GPU_CPU_temp_logger
sudo chmod +x ./temp_logger
```

### Run(temp_logger.sh)
```
# temp_logger.sh <interval sec> <timeout sec> <--no-gpu>
sudo ./temp_logger.sh 5 120
```
## Output
You can see ```.csv``` file of each gpu, average gpu temperature, and cpu 
### Sample
```
Timestamp, NVMe_Temperature, CPU0_Tctl, CPU1_Tctl, GPU0_Temperature, GPU1_Temperature, GPU2_Temperature, GPU3_Temperature, GPU4_Temperature, GPU5_Temperature, GPU6_Temperature, GPU7_Temperature, MEM_TOTAL_MB, MEM_USED_MB
2024-08-04 20:22:58, 28, 27, 27, 29, 30, 29, 30, 29, 29, 29, 30, 257788MB, 3204MB
2024-08-04 20:23:03, 28, 27, 27, 30, 30, 30, 30, 29, 29, 29, 30, 257788MB, 3204MB
2024-08-04 20:23:08, 28, 27, 27, 29, 30, 29, 30, 29, 29, 30, 30, 257788MB, 3197MB
2024-08-04 20:23:13, 28, 41, 42, 45, 43, 41, 41, 40, 40, 46, 43, 257788MB, 27034MB
2024-08-04 20:23:18, 28, 44, 45, 53, 54, 52, 52, 50, 51, 56, 54, 257788MB, 68727MB
2024-08-04 20:23:24, 28, 46, 44, 56, 58, 56, 55, 54, 55, 59, 58, 257788MB, 108125MB
2024-08-04 20:23:29, 28, 46, 46, 58, 60, 58, 58, 56, 58, 60, 60, 257788MB, 144105MB
2024-08-04 20:23:34, 28, 47, 46, 60, 62, 60, 59, 57, 59, 63, 62, 257788MB, 175374MB
2024-08-04 20:23:39, 28, 48, 46, 61, 63, 61, 60, 59, 61, 64, 61, 257788MB, 204340MB
2024-08-04 20:23:45, 28, 48, 47, 62, 63, 62, 61, 60, 62, 65, 64, 257788MB, 233583MB
2024-08-04 20:23:50, 28, 49, 48, 62, 65, 62, 62, 60, 62, 65, 64, 257788MB, 244527MB
2024-08-04 20:23:55, 28, 49, 47, 61, 63, 61, 60, 58, 61, 63, 63, 257788MB, 252990MB
2024-08-04 20:24:01, 28, 48, 46, 58, 60, 58, 57, 56, 58, 61, 60, 257788MB, 230622MB
2024-08-04 20:24:06, 28, 47, 44, 55, 58, 55, 54, 53, 55, 58, 57, 257788MB, 97991MB
2024-08-04 20:24:11, 28, 46, 43, 54, 56, 53, 52, 51, 53, 57, 56, 257788MB, 71153MB
2024-08-04 20:24:17, 28, 46, 43, 53, 55, 53, 52, 51, 53, 57, 56, 257788MB, 133352MB
2024-08-04 20:24:22, 28, 46, 44, 55, 56, 55, 53, 52, 54, 58, 57, 257788MB, 159107MB
2024-08-04 20:24:27, 28, 48, 46, 55, 57, 55, 54, 53, 54, 59, 58, 257788MB, 183860MB
2024-08-04 20:24:32, 28, 49, 46, 56, 57, 56, 54, 53, 55, 59, 58, 257788MB, 172744MB
2024-08-04 20:24:38, 28, 49, 47, 55, 58, 56, 54, 53, 55, 59, 58, 257788MB, 137823MB
2024-08-04 20:24:43, 27, 49, 47, 56, 58, 56, 54, 54, 55, 59, 58, 257788MB, 107101MB
```
### Data visualization(plot.py)
```
# python3 plot.py <.csv path> <graph title>
python3 plot.py thermo_data.csv "DG4R-A6000-8 stress test(24hr.)"
```
## Output
Few seconds later, the webpage is popped up and you can check the linear graph of the thermal data from the GPU.
And also the .png image file is generated exist path. This data shows 24 hour GPU stress test in server that consist of 8 of NVIDIA RTX A6000 GPUs cooled by our [DLC](https://deepgadget.com/Dg4r/?lang=en)(Direct-to-chip Liquid Cooling) system. 
![image](https://github.com/user-attachments/assets/f9a1b589-5030-4645-bfd5-738186623848)
![image](https://github.com/user-attachments/assets/09265d84-d0cf-49cf-82b8-b3a04cbcadbe)



## Authors

Jinseo Choi

## Version History

* 0.1
    * Initial Release
* 0.2

## TODO:
* 
* AMD CPU Tctl 보정값 추가(보정값이 적용되는 타이밍을 알아야함)

## DONE:
* CPU 온도 안찍히는 버그수정
* 인텔 CPU 온도측정 지원
* 멀티소켓 CPU 온도측정 지원
