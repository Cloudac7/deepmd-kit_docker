FROM nvidia/cuda:9.0-cudnn7-devel-centos7
LABEL maintainer "Tim Chen timchen314@163.com"

RUN yum makecache && yum install -y epel-release \
    centos-release-scl 
RUN rpm --import /etc/pki/rpm-gpg/RPM* 
# bazel, gcc, gcc-c++ and path are needed by tensorflow;   
# autoconf, automake, cmake, libtool, make, wget are needed for protobut et. al.;  
# epel-release, cmake3, centos-release-scl, devtoolset-4-gcc*, scl-utils are needed for deepmd-kit(need gcc5.x);
# unzip are needed by download_dependencies.sh.
RUN yum install -y automake autoconf \
    bzip bzip2 cmake cmake3 \
    devtoolset-4-gcc* \
    git gcc gcc-c++ libtool \
    make mpich-3.2* patch rpm-build rpmdevtools \
    scl-utils unzip vim wget \
    python3 python3-pip
RUN mv /usr/bin/python /usr/bin/python.bak && \
    sed -i 's;/usr/bin/python;/usr/bin/python2;g' /usr/bin/yum && \
    sed -i 's;/usr/bin/python;/usr/bin/python2;g' /usr/libexec/urlgrabber-ext-down &&\
    ln -s /usr/bin/python3 /usr/bin/python && \
    ln -s /usr/bin/pip3 /usr/bin/pip

ARG tensorflow_version=1.12
ENV tensorflow_root=/opt/tensorflow \
    deepmd_root=/opt/deepmd \
    deepmd_source_dir=/root/deepmd-kit \
    tensorflow_version=$tensorflow_version
RUN pip install numpy && \
    pip install tensorflow-gpu==${tensorflow_version}.0
# Install NCCL for multi-GPU communication
RUN cd /root && git clone https://github.com/NVIDIA/nccl.git && cd nccl && \
    make CUDA_HOME=/usr/local/cuda -j NVCC_GENCODE="-gencode=arch=compute_70,code=sm_70" && \
    make PREFIX=/usr/local/cuda install
ENV LD_LIBRARY_PATH /usr/local/cuda/lib64/stubs:/usr/local/lib:/usr/local/cuda/lib:/usr/local/cuda/lib64:/usr/local/cuda/extras/CUPTI/lib64:$LD_LIBRARY_PATH
ENV PATH /usr/local/cuda/bin/:/usr/lib64/mpich-3.2/bin/:$PATH 
# If download lammps with git, there will be errors during installion. Hence we'll download lammps later on.
RUN cd /root && \
    git clone https://github.com/deepmodeling/deepmd-kit.git -b "r0.12" deepmd-kit && \
    git clone https://github.com/tensorflow/tensorflow tensorflow -b "r$tensorflow_version" --depth=1 && \
    cd tensorflow
# install bazel for version 0.15.0
RUN wget https://github.com/bazelbuild/bazel/releases/download/0.15.0/bazel-0.15.0-installer-linux-x86_64.sh && \
    bash bazel-0.15.0-installer-linux-x86_64.sh 
# install tensorflow C lib
RUN ln -s /usr/local/cuda/lib64/stubs/libcuda.so /usr/local/cuda/lib64/stubs/libcuda.so.1 && \
    cd /root/tensorflow && \
    /bin/echo -e "\n\ny\nn\nn\nn\ny\n9.0\n\n7.0\n\nn\n2.4.2\n\n3.5,5.2,6.0,6.1,7.0\nn\n\nn\n\n\n">install_input && \
    ./configure < install_input && \
    # export LD_LIBRARY_PATH here
    # for the following part should not be included in the final image
    LD_LIBRARY_PATH=/usr/local/cuda/lib64/stubs:${LD_LIBRARY_PATH} && \
    bazel build -c opt \
    # --incompatible_load_argument_is_label=false
    --copt=-msse4.2 --config=cuda //tensorflow:libtensorflow_cc.so \ 
    --action_env="LD_LIBRARY_PATH=${LD_LIBRARY_PATH}"
# install the dependencies of tensorflow and xdrfile
RUN cd /root/tensorflow && \
    sed -i 's;PROTOBUF_URL=.*;PROTOBUF_URL=\"https://mirror.bazel.build/github.com/google/protobuf/archive/v3.6.0.tar.gz\";g' tensorflow/contrib/makefile/download_dependencies.sh && \
    tensorflow/contrib/makefile/download_dependencies.sh && \
    cd /root/tensorflow && \
    mkdir /tmp/proto && \
    cd tensorflow/contrib/makefile/downloads/protobuf/ && \
    ./autogen.sh && ./configure --prefix=/tmp/proto/ && \
    make -j20 && make install && \
    cd /root/tensorflow/tensorflow/contrib/makefile/downloads/eigen/ && \
    mkdir /tmp/eigen && mkdir build_dir && \
    cd build_dir && cmake -DCMAKE_INSTALL_PREFIX=/tmp/eigen/ ../ && \
    make install &&\
    cd /root/tensorflow/tensorflow/contrib/makefile/downloads/nsync/ && \
    mkdir /tmp/nsync && mkdir build_dir && cd build_dir && \
    cmake -DCMAKE_INSTALL_PREFIX=/tmp/nsync/ ../ && \
    make && make install &&\
    cd /root/tensorflow/tensorflow/contrib/makefile/downloads/absl && \
    bazel build && \
    mkdir -p $tensorflow_root/include/ && \
    rsync -avzh --include '*/' --include '*.h' --exclude '*' absl $tensorflow_root/include/
RUN cd /root/tensorflow/ && mkdir -p $tensorflow_root/lib && \
    cp bazel-bin/tensorflow/libtensorflow_cc.so $tensorflow_root/lib/ && \
    cp bazel-bin/tensorflow/libtensorflow_framework.so $tensorflow_root/lib/ && \
    cp /tmp/proto/lib/libprotobuf.a $tensorflow_root/lib/ && \
    cp /tmp/nsync/lib64/libnsync.a $tensorflow_root/lib/ && \
    mkdir -p $tensorflow_root/include/tensorflow && \
    cp -r bazel-genfiles/* $tensorflow_root/include/ && \
    cp -r tensorflow/cc $tensorflow_root/include/tensorflow && \
    cp -r tensorflow/core $tensorflow_root/include/tensorflow && \
    cp -r third_party $tensorflow_root/include && \
    cp -r /tmp/proto/include/* $tensorflow_root/include && \
    cp -r /tmp/eigen/include/eigen3/* $tensorflow_root/include && \
    cp -r /tmp/nsync/include/*h $tensorflow_root/include && \
    cd $tensorflow_root/include && \ 
    find . -name "*.cc" -type f -delete && \
    rm -fr /tmp/proto /tmp/eigen /tmp/nsync
# `source /opt/rh/devtoolset-4/enable` to set gcc version to 5.x, which is needed by deepmd-kit.
# install deepmd
RUN cd /root && source /opt/rh/devtoolset-4/enable && \ 
    alias cmake='cmake3' && cd /root && \
    cd $deepmd_source_dir/source && \
    mkdir build && cd build &&\
    LD_LIBRARY_PATH=/usr/local/cuda/lib64/stubs:${LD_LIBRARY_PATH} && \
    cmake3 -DTF_GOOGLE_BIN=true -DTENSORFLOW_ROOT=$tensorflow_root -DCMAKE_INSTALL_PREFIX=$deepmd_root .. && \
    make -j20 && make install && \
    cp $deepmd_source_dir/data/raw/* $deepmd_root/bin/ && \
    ls $deepmd_root/bin
# install lammps
RUN cd /opt && wget https://codeload.github.com/lammps/lammps/tar.gz/stable_5Jun2019 && \
    tar xf stable_5Jun2019 && source /opt/rh/devtoolset-4/enable && \
    cd $deepmd_source_dir/source/build && make lammps && \
    cd /opt/lammps*/src/ && \
    cp -r $deepmd_source_dir/source/build/USER-DEEPMD . && \
    LD_LIBRARY_PATH=/usr/local/cuda/lib64/stubs:${LD_LIBRARY_PATH} && \
    make yes-user-deepmd && make mpi -j4

RUN ln -s $deepmd_root/bin/dp_train /usr/bin/dp_train && \
    ln -s $deepmd_root/bin/dp_frz /usr/bin/dp_frz && \
    ln -s $deepmd_root/bin/dp_test /usr/bin/dp_test && \
    ln -s $deepmd_root/bin/dp_ipi /usr/bin/dp_ipi && \
    ln -s /opt/lammps-stable/src/lmp_mpi /usr/bin

RUN rm -rf /root/tensorflow /root/deepmd-kit /root/nccl

CMD ["/bin/bash"]