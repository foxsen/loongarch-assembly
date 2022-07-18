# 龙芯汇编实验环境

本项目实现了一个简易的龙芯LoongArch架构实验环境。它包括一个可以用于在PC上编译和运行LoongArch汇编的docker环境，以及若干汇编源代码案例。

## docker环境

克隆本项目的代码之后，再下载编译工具链和qemu模拟器：

    wget -c https://github.com/foxsen/qemu-loongarch-runenv/releases/download/toolchain/loongarch64-clfs-2021-12-18-cross-tools-gcc-full.tar.xz
    wget -c https://github.com/foxsen/loongarch-assembly/releases/download/qemu/qemu-6.2.50.loongarch64.tar.gz

使用如下命令可以生成一个docker镜像：

    docker build -t loongarch-assembly .

然后，用docker run -it loongarch-assembly /bin/bash可以运行该环境，输入make编译和运行案例代码。

可以从docker hub直接下载制作好的镜像文件：
    docker pull foxsen76/loongarch-assembly

## 案例

### hello-world.S

调用write系统调用，输出"Hello World!"，然后调用exit系统调用退出。

### bubble-sort.S

冒泡排序实现

## 参考资料

* [龙芯架构参考手册](https://github.com/loongson/LoongArch-Documentation/releases/latest/download/LoongArch-Vol1-v1.00-CN.pdf)
* [龙芯3A5000处理器用户手册](https://github.com/loongson/LoongArch-Documentation/releases/latest/download/Loongson-3A5000-usermanual-v1.03-CN.pdf)
* [LoongArch汇编快速入门](./loongarch-assembly.md)
