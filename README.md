# GPU_CPU_temp_logger

## Description
Simple shell script for GPU and CPU temperature logging.

## Getting Started

### Dependencies

* Ubuntu 20.04 or higher
* CUDA 12.2 toolkit
* [gpu-burn](https://github.com/wilicc/gpu-burn)
* [stress](https://howtoinstall.co/package/stress)

### Install
```
git clone https://github.com/DEEPGadget/GPU_CPU_temp_logger.git
```

### Execution
```
sudo bash temp_logger.sh
```

## Output
You can see ```.log``` file of each gpu, average gpu temperature, and cpu 

## Authors

Jinseo Choi


## Version History

* 0.1
    * Initial Release

## TODO:
* 하드코딩된 파라미터 입력 값 받아서 적용될 수 있도록 수정 
* 파워 Usage 그래프 추가 
* 데이터 측정 인터벌 수정 <- user가 간격 정할 수 있게 변경 