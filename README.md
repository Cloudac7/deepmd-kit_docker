# Docker Engine Utility for DeePMD-kit

[DeePMD-kit](https://github.com/deepmodeling/deepmd-kit#run-md-with-native-code) is a deep learning package for many-body potential energy representation, optimization, and molecular dynamics.

This docker project is set up to simplify the installation process of DeePMD-kit. And GPU support is added in this fork (`CUDA==9.0, CuDNN==7, NCCL==2.4.2`).

Because of the error `/usr/bin/ld: warning: libcuda.so.1` could not be solved properly for tensorflow 1.8, in this fork the version is updated to 1.12. The solution to the error is `ln -s /usr/local/cuda/lib64/stubs/libcuda.so /usr/local/cuda/lib64/stubs/libcuda.so.1 && LD_LIBRARY_PATH=/usr/local/cuda/lib64/stubs:${LD_LIBRARY_PATH}`.

But another issue appeared when add `/usr/local/cuda/lib64/stubs` to `$LD_LIBRARY_PATH` from `ENV` flag, so it is exported only when necessary.

Thanks to @[TimChen314](https://github.com/TimChen314) for the inital creation of this docker project.

Thanks to @[frankhan91](https://github.com/frankhan91) for the maintainess and impression of the CPU version. (Which is stored in the CPU branch.)

## QuickStart 

### Installation

About the steps of installation, you could visit page https://www.tensorflow.org/install/docker for reference.

#### Installing NVIDIA Driver

Please check page https://github.com/NVIDIA/nvidia-docker/wiki/Frequently-Asked-Questions#how-do-i-install-the-nvidia-driver for descrption in detail.

#### Installing nvidia-docker

To enable the support of GPUs for your container, please following the steps on https://github.com/NVIDIA/nvidia-docker to install nvidia-docker. It is the recommended way for users with Docker 19.03 installed. 

While for users with old versions, the deprecated nvidia-docker2 is needed. The up-to-date nvidia-docker is not supported by docker-compose as well. The steps of installation could be found at https://github.com/NVIDIA/nvidia-docker/tree/v2.1.0. For users had installed latest Docker 19.03, as described nvidia-docker2 packages are deperated. Don't worry, from our test, nvidia-docker2 could work well with Docker 19.03, as well as docker-compose.

Note that in the future, nvidia-docker2 packages will no longer be supported. So the description of nvidia-docker2 will be removed after the fatal upgrade of docker-compose.

### Building

```
git clone https://github.com/Cloudac7/deepmd-kit_docker.git deepmd-kit_docker
cd deepmd-kit_docker && docker build -f Dockerfile -t deepmd-kit_docker:gpu .
```

It will take a few minutes to download necessary package and install them.

The `ENV` statement in Dockerfile sets the install prefix of packages. These environment variables can be set by users themselves.

The `ARG tensorflow_version` specifies the version of tensorflow to install, which can be set during the build command through `--build-arg tensorflow_version=1.12`.

### Training

#### Usage

Suppose you had put the `set.00x` folder as well as `type.raw` in `example/data/water`, while the `train.json` is in `example/train`. The structure of the `example` folder looked like this:

```
example
├── data
│   └── water
│       ├── set.000
│       │   ├── box.npy
│       │   ├── coord.npy
│       │   └── energy.npy
│       ├── set.001
│       │   ├── box.npy
│       │   ├── coord.npy
│       │   └── energy.npy
│       ├── set.002
│       │   ├── box.npy
│       │   ├── coord.npy
│       │   └── energy.npy
...     ... ...
│       └── type.raw
└── train
    └── train.json
```

To start the train process, just excute:

``` 
docker run -d -P \
    --gpus all \
    --name deepmd \
    --mount type=bind,source=/absolute/path/of/example,target=/root/system \
    deepmd-kit:cuda-9.0-centos7 \
    /bin/bash -c "cd /root/system/train && dp_train train.json"
```

`/absolute/path/of/example` is the absolute path of the local `example` folder, while `/root/system` is the target path for the folder to place in the docker container. Then  `/bin/bash -c "cd /root/system/train && dp_train train.json"` could enter the target folder and start the train process.

To modify the GPU to run on, please change  `all` to the number of specific GPUs, such as `0,1`. 

For nvidia-docker2 users, just replace ` --gpus all`  to `--runtime nvidia `. But for changing the GPUs to use, you need to add `-e CUDA_VISIBLE_DEVICES=0,1 `  after `docker run`.

#### Using docker-compose to Simplify the command

[Docker Compose](https://docs.docker.com/compose/) could be used for training in a easy way. A `docker-compose.yml` for example had been put in this branch, and `runtime: nvidia` could be added to enable the gpu support. Before going ahead, for users that item `runtime: nvidia` is not supportted, `/etc/docker/daemon.json`  should be edited like the following (from https://github.com/docker/app/issues/241):

```
// Snippet from "/etc/docker/daemon.json" on my machine
{
  // ...
  "default-runtime": "nvidia",
  "runtimes": {
    "nvidia": {
      "path": "/usr/bin/nvidia-container-runtime",
      "runtimeArgs": []
    }
  }
}
```

Then you could edit  `docker-compose.yml` , while changing the path of your system (including `set.00x`,  `train.json`,  etc.). For more detail information about the file, please read the example `docker-compose.yml`. With everything ready, just use `docker-compose up` to start the training.

