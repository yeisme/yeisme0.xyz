+++
title = "Opencv_gamma"
date = "2025-03-28T18:09:07+08:00"
description = ""
tags = []
categories = ["OpenCV","C++","代码优化"]
series = []
aliases = []
image = ""
draft = false
+++
# 伽马变换：图像处理函数从理论到工程

> 2025-03-28 图像处理课程笔记
> 代码链接：[GitHub - yeisme/opencv\_learn](https://github.com/yeisme/opencv_learn)

## 理论回顾：不只是数学公式

伽马变换是图像处理中一种重要的非线性变换技术，主要用于调整图像的亮度和对比度

$$
s = c * r^{\gamma}
$$

- r 是输入像素值（通常归一化到 0-1 范围）
- s 是输出像素值
- c 是常数，通常设为 1
- γ (gamma) 是伽马值，控制变换的曲线形状
    - **γ < 1**: 增强图像暗区细节，压缩亮区动态范围
    - **γ > 1**: 增强图像亮区细节，压缩暗区动态范围
    - **γ = 1**: 线性变换，输出等于输入

## 实践部分

> 原图

![[img.jpg]]

> 使用 ffmpeg 修改为灰度图

```
ffmpeg -i img.jpg -vf format=gray -pix_fmt gray output_gray.jpg
```

![[img 1.jpg]]

![[Pasted image 20250328173020.png]]

## 萌新版本：v1

```cpp
// 萌新写法：无任何注释，无任何异常处理，无任何参数检查，无任何性能优化，主打一个能跑就行
void gamma_v1(cv::Mat iMat, cv::Mat oMat, float gamma, float c)
{
    uchar input_data = 0;
    uchar output_data = 0;
    for (int i = 0; i < iMat.rows; i++)
    {
        for (int j = 0; j < iMat.cols; j++)
        {
            input_data = iMat.at<uchar>(i, j);
            output_data = c * std::pow(input_data, gamma);
            oMat.at<uchar>(i, j) = output_data;
        }
    }
}

```

> 调用

```cpp
// gamma 变化后 0 < gamma  < 1
cv::Mat img_gamma_0_5(img.size(), img.type());
gamma_v1(img, img_gamma_0_5, 0.5, 1.0);
cv::imshow("Gamma 0.5", img_gamma_0_5);
```

![[Pasted image 20250328153608.png]]

很明显，这个萌新代码漏洞百出

| 问题等级 | 问题描述                  | 潜在后果              |
| -------- | ------------------------- | --------------------- |
| 致命     | 未做数值归一化            | 暗区细节完全丢失      |
| 致命     | 直接对uchar做pow运算      | 整数溢出导致图像噪点  |
| 严重     | 无参数有效性检查          | gamma=0等导致程序崩溃 |
| 严重     | Mat对象值传递造成内存拷贝 | 大图像处理内存暴涨    |
| 中度     | 逐像素访问效率低下        | 处理2K图像耗时超500ms |
| 轻微     | 缺乏代码注释和异常处理    | 可维护性差            |

这里有一点要说明

由于OpenCV的`cv::Mat`类设计的特性，尽管`gamma_v1`函数接收的是`cv::Mat`的值而不是引用，它仍然可以修改原始图像数据，原因如下：

1. **智能指针结构**：`cv::Mat`是一个只包含头部信息和指向实际数据的指针的结构，它使用了引用计数机制。
2. **仅复制头信息**：当你通过值传递`cv::Mat`时，只有矩阵的头信息被复制，而实际的像素数据仍然共享同一块内存。
3. **共享数据**：函数内的`oMat`和函数外的`img_gamma_v1`指向相同的像素数据块，因此对`oMat`的修改直接影响原始数据。

## 第一次改进：v2 参数检查

```cpp

/*
改进
1. 添加参数检查
2. 返回值改为 bool
3. oMat 不能溢出（像素值范围 0-255）
*/
bool gamma_v2(cv::Mat iMat, cv::Mat oMat, float gamma, float c, std::string &err)
{

    // 输入检查
    if (iMat.empty())
    {
        err = "Input image is empty";
        return false;
    }

    // 检查单通道
    if (iMat.channels() != 1)
    {
        err = "Input image is not single channel";
        return false;
    }

    // oMat 与 iMat 尺寸一致
    if (iMat.size() != oMat.size())
    {
        err = "Input image and output image size mismatch";
        return false;
    }

    // gamma 范围检查
    if (gamma <= 0)
    {
        err = "Gamma value must be greater than 0";
        return false;
    }

    // c 范围检查
    if (c <= 0)
    {
        err = "C value must be greater than 0";
        return false;
    }

    // gamma == 1 时，不需要处理
    if (gamma == 1)
    {
        iMat.copyTo(oMat);
        return true;
    }

    float input_data = 0;
    float output_data = 0;
    for (int i = 0; i < iMat.rows; i++)
    {
        for (int j = 0; j < iMat.cols; j++)
        {
            float result = c * std::pow(input_data, gamma);
            if (result > 255.0f)
            {
                output_data = 255;
            }
            else if (result < 0.0f)
            {
                output_data = 0;
            }
            else
            {
                output_data = static_cast<uchar>(result);
                oMat.at<uchar>(i, j) = output_data;
            }
        }
    }

    return true;
}

```

> 调用

```cpp
auto img_gamma_v2 = cv::Mat(img.size(), img.type());
ok = gamma_v2(img, img_gamma_v2, 0.8, 1.0, err);
if (!ok)
{
    std::cerr << "Error: " << err << std::endl;
    return 1;
}
```

v1 和 v2 函数都调用 100 次，对比时间，发现基本没有影响，每次调用大概花费 120 ms

```
v1: 12732ms
v2: 4151ms
```

## 第二次改进：v3 多进程优化

```cpp

/*
硬件优化
1. openmp 并行化
*/

#pragma omp parallel for
for (int i = 0; i < iMat.rows; i++)
{
    for (int j = 0; j < iMat.cols; j++)
    {
        // 设置为局部变量，避免多线程竞争
        float input_data = 0;
        float output_data = 0;
        input_data = iMat.at<uchar>(i, j);

        output_data = c * std::pow(input_data, gamma);
        if (output_data > 255)
        {
            output_data = 255;
        }
        else if (output_data < 0)
        {
            output_data = 0;
        }
        oMat.at<uchar>(i, j) = output_data;
    }
}

```

> 调用 100 次对比时间

```cpp
// 优化版本 v3 openmp
auto start3 = utime::now();
for (int i = 0; i < 100; i++)
{
    auto img_gamma_v3 = cv::Mat(img.size(), img.type());
    ok = gamma_v3(img, img_gamma_v3, 0.8, 1.0, err);
    if (!ok)
    {
        std::cerr << "Error: " << err << std::endl;
        return 1;
    }
}
// cv::imwrite("Gamma_v3.jpg", img_gamma_v3);
auto end3 = utime::now();
std::cout << "v3: " << duration_cast<milliseconds>(end3 - start3).count() << "ms" << std::endl;
```

```
v1: 12732ms
v2: 4151ms
v3: 2206ms
```

每次调用花费约 23 ms，提升约5倍，但这个还不够，这只是一张 150k 左右的图片，还能怎么优化呢？

## 第三次改进：v4 算法优化 LUT

创建查找表，参数检查都不动

```cpp
/*
算法优化
1. LUT 表优化
*/

// LUT 表
cv::Mat lookUpTable(1, 256, CV_8U);
uchar *lut = lookUpTable.ptr();
for (int i = 0; i < 256; i++)
{
    float result = c * std::pow(i, gamma);
    if (result > 255)
        lut[i] = 255;
    else if (result < 0)
        lut[i] = 0;
    else
        lut[i] = static_cast<uchar>(result);
}

#pragma omp parallel for
for (int i = 0; i < iMat.rows; i++)
{
    for (int j = 0; j < iMat.cols; j++)
    {
        uchar input_value = iMat.at<uchar>(i, j);
        oMat.at<uchar>(i, j) = lut[input_value];
    }
}
```

```
v1: 12732ms
v2: 4151ms
v3: 2206ms
v4: 1474ms
```

每次调用花费约14 ms，从120ms到14ms，性能提升了约8.5倍（缓存的魅力，空间换时间），将时间复杂度从 O(N^2)降为 O(N)
