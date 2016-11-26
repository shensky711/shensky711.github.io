---
layout: post
title: java动态代理
tags: [HansChen,java,proxy,动态代理]
excerpt: 动态代理是java的一大特性，动态代理的优势就是实现无侵入式的代码扩展。它可以增强我们原有的方法，比如常用的日志监控,添加缓存等，也可以实现方法拦截，通过代理方法修改原方法的参数和返回值等
---

#  概述
动态代理是java的一大特性，动态代理的优势就是实现无侵入式的代码扩展。它可以增强我们原有的方法，比如常用的日志监控,添加缓存等，也可以实现方法拦截，通过代理方法修改原方法的参数和返回值等。
要了解动态代理，我们需要先看看什么是静态代理

# 静态代理
首先你有一个接口：
```java
public interface Api {

    String doSomething(String input);
}
```
这个接口有一个原始的实现：
```java
public class ApiImpl implements Api {

    @Override
    public String doSomething(String input) {
        return input + "原始方法";
    }
}
```
现在问题来了，有一个新的需求，我需要在所有调用`doSomething`的地方都添加一个log，那怎么办呢？我们当然可以在原有代码上直接加上log，但是ApiImpl里面的log真的是那段代码需要的吗？如果不修改原有代码，能不能实现？当然可以，如，我们添加一个代理类：
```java
public class ApiProxy implements Api {

    private Api mBase;

    public ApiProxy(Api base) {
        mBase = base;
    }

    @Override
    public String doSomething(String input) {
        System.out.println("someone call me~");
        return mBase.doSomething(input);
    }
}
```
这样，通过ApiProxy我们就是实现静态代理，这里只是简单的添加了log，我们完全可以在ApiProxy的doSomething方法里面，篡改输入参数input以及返回值，从而做一些坏事~

# 动态代理
在上面静态代理例子中，我们已经实现了代理的功能，那为何还需要动态代理呢？设想一下以下两种情况

 - 如果Api接口类中有100个方法，需要为每个方法都添加log
 - 项目中有100个类，需要为每个类的方法都添加log

对于第一种情况，如果使用静态代理，那就只能这样了：
```java
public class ApiProxy implements Api {

    private Api mBase;

    public ApiProxy(Api base) {
        mBase = base;
    }

    @Override
    public String doSomething(String input) {
        System.out.println("someone call me~");
        return mBase.doSomething(input);
    }

    @Override
    public String doSomething1(String input) {
        System.out.println("someone call me~");
        return mBase.doSomething1(input);
    }
    
    //为每个方法添加实现......
}
```
而对于第二种情况，就只能新建100个代理类了。这种处理方式肯定不是我们喜欢的，怎么优雅地去解决了？动态代理这时候终于可以上场了。

JDK提供了动态代理方式，可以简单理解为JVM可以在运行时帮我们动态生成一系列的代理类，这样我们就不需要手写每一个静态的代理类了，比如:

1. 实现InvocationHandler
```java
public class ApiHandler implements InvocationHandler {

    private Api mBase;

    public ApiHandler(Api base) {
        mBase = base;
    }

    /**
     * 此方法会在proxy实例调用方法的时候回调
     *
     * @param proxy  代理对象
     * @param method 被调用的方法
     * @param args   调用参数
     * @return
     * @throws Throwable
     */
    @Override
    public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
        System.out.println("someone call me~");
        return method.invoke(mBase, args);
    }
}
```

2. 动态创建代理类
```java
    private static void proxyTest() {
        ClassLoader loader = Api.class.getClassLoader();//加载代理类的ClassLoader
        Class[] interfaces = new Class[]{Api.class};//需要代理的接口
        Api proxy = (Api) Proxy.newProxyInstance(loader, interfaces, new ApiHandler(new ApiImpl()));//创建代理对象
        proxy.doSomething("test");//会调用ApiHandler的invoke方法
        proxy.doSomething1("test");//会调用ApiHandler的invoke方法
    }
```

这样，一个动态代理就完成了，但这里有个需要注意的，动态代理只能代理接口，也就是说interfaces数组里面，只能放接口Class

# 代理Hook
代理有比原始对象更强大的能力，如果我们自己创建代理对象，然后把原始对象替换为我们的代理对象，那么就可以在这个代理对象为所欲为了；修改参数，替换返回值，我们称之为Hook。
首先我们得找到被Hook的对象，也就是Hook点；什么样的对象比较适合Hook呢？**静态变量和单例**；在一个进程之内，静态变量和单例变量是不容易发生变化的，所以容易定位，而普通的对象则要么无法标志，要么容易改变，我们根据这个原则找到所谓的Hook点。
一般Hook的步骤有：

1. 寻找Hook点，如静态变量或单例对象，尽量Hook pulic的对象和方法，非public不保证每个版本都一样，需要适配。
2. 选择合适的代理方式，如果是接口可以用动态代理；如果是类可以手动写代理也可以使用cglib
3. 用代理对象替换原始对象，如果没有公开是geter/setter方法，可以使用反射

