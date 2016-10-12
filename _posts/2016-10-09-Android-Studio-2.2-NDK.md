---
layout: post
title:  Android Studio 2.2 NDK开发环境搭建
tags: [HansChen,Android Studio NDK,NDK开发,JNI,NDK]
excerpt: Android应用程序使用NDK的意义在这里就不说了，本文主要讲解如何在Android Studio 2.2下如何一步步搭建NDK开发环境
---

> 转载请标明出处，本文出自:【HansChen的博客 [http://blog.csdn.net/shensky711](http://blog.csdn.net/shensky711)】

Android应用程序使用NDK的意义在这里就不说了，本文主要讲解如何在Android Studio 2.2下如何一步步搭建NDK开发环境。

# 下载NDK和工具
Android Studio2.2开始推荐开发者使用CMake去构建本地代码，在构建之前，我们需先安装下面三个依赖：

 - **NDK**: a set of tools that allows you to use C and C++ code with Android.
 - **CMake**: an external build tool that works alongside Gradle to build your native library. You do not need this component if you only plan to use ndk-build. 
 - **LLDB**: the debugger Android Studio uses to debug native code.

![这里写图片描述](http://img.blog.csdn.net/20161009090144235)

我们可以使用SDK Manager进行下载，菜单位置：Tools > Android > SDK Manager，勾选后安装即可

# 创建或者导入native项目

## 创建工程
![这里写图片描述](http://img.blog.csdn.net/20161009085101005)
在这里要注意勾选这个`Include C++ Support`

接下来一路next最后finish，工程就创建好了。创建好之后系统默认生成了个demo。在Android Studio2.2下，目录结构发生了变化

![这里写图片描述](http://img.blog.csdn.net/20161009144008267)
**所有c/c++文件都应放置在src/main/cpp/目录**（以前是在jni目录）

# 配置build.gradle
```
android {
    ...

    defaultConfig {
        ...

        externalNativeBuild {
            cmake {
                //设置编译工具链
                arguments "-DANDROID_TOOLCHAIN=clang"
                //需编译生成的ABI类型
                abiFilters 'x86', 'x86_64', 'armeabi', 'armeabi-v7a', 'arm64-v8a'
            }
        }

        ndk {
            //打包进APK的ABI类型
            abiFilters "armeabi", "armeabi-v7a", "x86"
        }
    }

    externalNativeBuild {
        cmake {
            //配置CMakeLists.txt的路径
            path 'CMakeLists.txt'
        }
    }

    ...
}
```

![这里写图片描述](http://img.blog.csdn.net/20161009144008267)
配置之后，我们就会发现工程终于变成这种结构了，其中`cpp`里面的是源文件，`External Build Files`是CMakeLists文件。

当然，想要正常编译，我们还需要学习CMake文件，这里推荐一篇文章：[CMake 入门实战](http://www.hahack.com/codes/cmake/)