# LoongArch 架构汇编快速入门

本文简单介绍编写 LoongArch 架构的汇编程序所需要的一些知识，并提供了相应的实验环境和示例链接。龙芯常用的汇编器是 GNU as 汇编器，as 的具体使用可以参见: [Binutils 官方文档](https://sourceware.org/binutils/docs/as/)。

## 数据类型和常量

### 数据类型

* 所有 LoongArch 指令都是 32 位长的。
* 字节(byte) = 8 位(bit)
* 半字(half) = 2 个字节
* 字(word) = 4 个字节
* 双字(dword) = 8 个字节
* 注意，汇编里用 .long 定义的数据是 4 个字节

### 常量

* 数字直接输入，如：1234
* 单个字符用单引号，例如：'a'
* 字符串用双引号，例如："hello world"

## 寄存器和ABI

* LoongArch 下一共有 32 个通用定点寄存器
* 在汇编中，寄存器标志由 $ 符开头，寄存器表示可以有两种方式
    - 直接使用该寄存器对应的编号，例如：从 $0 到 $31，浮点则是 $f0 到 $f31。
    - 使用对应的寄存器名称，例如：$a0, $t1，详细含义参见 [龙架构 ABI 文档](https://loongson.github.io/LoongArch-Documentation/LoongArch-ELF-ABI-EN.html)。
* 栈的走向是从高地址到低地址

### 龙架构ABI

二进制程序接口( Application Binary Interface )是为了实现二进制模块之间的交互引入的人为约定，包括寄存器使用、如何在子程序之间传递参数，数据类型，对齐，系统调用等内容。龙架构的 ABI 总体遵循 SysV ABI 框架，架构相关的约定参见 [龙架构 ABI 文档](https://loongson.github.io/LoongArch-Documentation/LoongArch-ELF-ABI-EN.html)。

## 程序结构

包括数据声明和程序代码，通常保存为后缀 .s 或者 .S 的文本文件。一般先是数据声明，后是代码段。

### 数据声明

* 以汇编伪指令 .data 开始
* 声明程序用到的变量名字，并在内存中分配空间

### 代码

* 代码段以 .text 为开始标志
* 包括程序指令
* 程序入口为 main: 标签所在位置
* 程序结束时应该用 exit 系统调用（参见后文系统调用一节）

## 注释

* 一行中 # 字符之后的内容

## 一个 LoongArch 汇编程序模板

```bash

# 描述此程序名字和功能的注释
# Template.s
# 汇编程序模板

.data # 本行之后是数据声明
    数据申明 1
    数据申明 2
    ...

.text # 指令在本行之后开始

.global main
main:  # 程序入口
    指令 1
    指令 2
    ...
```


## 数据声明格式

声明的格式：

    name:       storage_type	value(s)	
    变量名:     数据类型         变量值     

* 创建给定类型、名字和值的变量，值是是该变量的初始值
* 注意：名字后面要跟英文冒号

例子：

    var1:		.word	3	# 声明一个 word 类型的变量 var1, 同时给其赋值为 3
    array1:		.byte	'a','b'	# 声明一个存储 2 个字符的数组 array1，并赋值 'a', 'b'
    array2:		.space	40	# 为变量 array2 分配 40 字节（bytes) 未使用的连续空间，当然，对于这个变量
    　　　　　　　　　　　　# 到底要存放什么类型的值， 最好事先声明注释下！
     
## 汇编伪指令

汇编伪指令 (directive) 是由 . 打头的一些特殊标记符，它指示汇编器做一些特定的动作，如前述介绍的 .word/.data 等。龙架构的汇编伪指令由 GNU as 汇编器支持的所有架构无关伪指令和它特有的伪指令组成。

架构无关伪指令的详细情况，可以参见 [as 伪指令文档](https://sourceware.org/binutils/docs/as/Pseudo-Ops.html)。常用的伪指令包括：

* .data/.text/.section 等，用于定义 elf 的 section （节）开始，把后续的代码或者数据放置到那个 elf 节
* .global，把函数名或者变量名声明为全局变量，例如汇编程序的 main 要定义为 global，缺省的链接才会成功
* .align n，定义 2^n 对齐
* .if/.ifxx/.elseif/.else/.endif，条件编译控制
* .macro，定义汇编宏代码块，可以带参数
* .ascii/.asciz，定义字符串，后者以 0 结尾
* .float/.double，定义单精度、双精度浮点
* .include，包含另一个汇编源文件

后者目前仅有几个，可以从 binutils 源代码 gas/config/tc-loongarch.c 中的 loongarch_pseudo_table 看到，包括：

* .align n，约定按 2^n 对齐后续地址
* .dword，定义 8 字节的双字
* .word, 字
* .half, 半字
* .dtprelword, dwarf 调试信息用的一种重定位伪指令
* .dtpreldword, dwarf 调试信息用的一种重定位伪指令

## 常用指令

* Load/Store 访存指令，参见 [龙架构存储指令](https://foxsen.github.io/archbase/sec-ISA.html#tab:mem-inst)
* 算术逻辑指令。参见 [龙架构 ALU 指令](https://foxsen.github.io/archbase/sec-ISA.html#tab:alu-inst)
* 控制流指令。参见 [龙架构控制指令](https://foxsen.github.io/archbase/sec-ISA.html#tab:control-inst)

## 地址空间安排

普通汇编程序可以使用 gcc 工具链提供的缺省链接脚本，由编译器选择缺省的程序代码段、数据段装载地址。如果有特殊需要，可以使用 GNU ld 链接程序的链接脚本支持，灵活指定代码或者数据被装载的地址。

## 代码案例和运行测试环境

参见这个 github 开源项目：[loongarch-assembly](https://github.com/foxsen/loongarch-assembly.git)。

