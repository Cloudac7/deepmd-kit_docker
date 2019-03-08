```
ERROR: /root/tensorflow/tensorflow/cc/BUILD:422:1: Linking of rule '//tensorflow/cc:ops/state_ops_gen_cc' failed (Exit 1):
crosstool_wrapper_driver_is_not_gcc failed: error executing command
  (cd /root/.cache/bazel/_bazel_root/efb88f6336d9c4a18216fb94287b8d97/execroot/org_tensorflow && \
  exec env - \
    LD_LIBRARY_PATH=/usr/local/cuda:/usr/local/nvidia/lib:/usr/local/nvidia/lib64 \
    PATH=/opt/conda3/bin:/usr/local/nvidia/bin:/usr/local/cuda/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    PWD=/proc/self/cwd \
  external/local_config_cuda/crosstool/clang/bin/crosstool_wrapper_driver_is_not_gcc -o bazel-out/host/bin/tensorflow/cc/ops/state_ops_gen_cc '-Wl,-rpath,$ORIGIN/../../../_solib_local/_U_S_Stensorflow_Scc_Cops_Sstate_Uops_Ugen_Ucc___Utensorflow'
'-Wl,-rpath,$ORIGIN/../../../_solib_local/_U@local_Uconfig_Ucuda_S_Scuda_Ccudart___Uexternal_Slocal_Uconfig_Ucuda_Scuda_Scuda_Slib' -Lbazel-out/host/bin/_solib_local/_U_S_Stensorflow_Scc_Cops_Sstate_Uops_Ugen_Ucc___Utensorflow -Lbazel-out/host/bin/_solib_local/_U@local_Uconfig_Ucuda_S_Scuda_Ccudart___Uexternal_Slocal_Uconfig_Ucuda_Scuda_Scuda_Slib '-Wl,-rpath,$ORIGIN/,-rpath,$ORIGIN/..,-rpath,$ORIGIN/../..' -Wl,-z,notext -Wl,-z,notext -pthread -Wl,-rpath,../local_config_cuda/cuda/lib64 -Wl,-rpath,../local_config_cuda/cuda/extras/CUPTI/lib64 -Wl,-no-as-needed -B/usr/bin/ -pie -Wl,-z,relro,-z,now -no-canonical-prefixes -pass-exit-codes '-Wl,--build-id=md5' '-Wl,--hash-style=gnu' -Wl,--gc-sections -Wl,-S -Wl,@bazel-out/host/bin/tensorflow/cc/ops/state_ops_gen_cc-2.params)
```
