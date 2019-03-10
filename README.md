# Docker Engine Utility for DeePMD-kit

[DeePMD-kit](https://github.com/deepmodeling/deepmd-kit#run-md-with-native-code) is a deep learning package for many-body potential energy representation, optimization, and molecular dynamics.

This docker project is set up to simplify the installation process of DeePMD-kit. And GPU support is added in this fork(Cuda==9.0, CuDNN==7.0, NCCL==2.4.2).

Because of the error `/usr/bin/ld: warning: libcuda.so.1` could not be solved for Tensorflow 1.8, in this fork the version is updated to 1.12. The solution to the error is `ln -s /usr/local/cuda/lib64/stubs/libcuda.so /usr/local/cuda/lib64/stubs/libcuda.so.1 && LD_LIBRARY_PATH=/usr/local/cuda/lib64/stubs:${LD_LIBRARY_PATH}`.

Thanks to @[TimChen314](https://github.com/TimChen314) for the inital creation of this docker project.

Thanks to @[frankhan91](https://github.com/frankhan91) for the maintainess and impression of the CPU version.

## QuickStart 

```
git clone https://github.com/Cloudac7/deepmd-kit_docker_GPU.git deepmd-kit_docker
cd deepmd-kit_docker && docker build -f Dockerfile -t deepmd-kit_docker:gpu .
```

It will take a few minutes to download necessary package and install them.

The `ENV` statement in Dockerfile sets the install prefix of packages. These environment variables can be set by users themselves.

The `ARG tensorflow_version` specifies the version of tensorflow to install, which can be set during the build command through `--build-arg tensorflow_version=1.12`.

Version of miniconda is limitted to 4.5.1 for python 3.6 to support tf-1.12.