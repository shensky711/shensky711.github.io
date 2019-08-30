---
layout: post
title: Robolectric使用教程
tags: [单元测试,Robolectric]
categories: 
- 测试
---

# 概述

Android的单元测试可以分为两部分：

 1. Local unit tests：运行于本地JVM
 2. Instrumented test：运行于真机或者模拟器

如果使用Local测试，需要保证测试过程中不会调用Android系统API，否则会抛出RuntimeException异常，因为Local测试是直接跑在本机JVM的，而之所以我们能使用Android系统API，是因为编译的时候，我们依赖了一个名为“android.jar”的jar包，但是jar包里所有方法都是直接抛出了一个RuntimeException，是没有任何任何实现的，这只是Android为了我们能通过编译提供的一个Stub！当APP运行在真实的Android系统的时候，由于类加载机制，会加载位于framework的具有真正实现的类。由于我们的Local是直接在PC上运行的，所以调用这些系统API便会出错。
那么问题来了，我们既要使用Local测试，但测试过程又难免遇到调用系统API那怎么办？其中一个方法就是mock objects，比如借助Mockito，另外一种方式就是使用`Robolectric`， Robolectric就是为解决这个问题而生的。它实现一套JVM能运行的Android代码，然后在unit test运行的时候去截取android相关的代码调用，然后转到他们的他们实现的Shadow代码去执行这个调用的过程

<!-- more -->

# 如何使用？

## 为项目添加依赖
```gradle
testCompile "org.robolectric:robolectric:3.1.4"
```

Robolectric在第一次运行时，会下载一些sdk依赖包，每个sdk依赖包大概50M，下载速度比较慢，用户可以直接在网上下载相应依赖包，放置在本地maven仓库地址中，默认路径为：`C:\Users\username\.m2\repository\org\robolectric`

## 指定RobolectricTestRunner为运行器
为测试用例添加注解,指定测试运行器为RobolectricTestRunner。注意，这里要通过Config指定`constants = BuildConfig.class`，Robolectric 会通过constants推导出输出路径，如果不进行配置，Robolectric可能不能找到你的manifest、resources和assets资源
```java
@RunWith(RobolectricTestRunner.class)
@Config(constants = BuildConfig.class)
public class MainActivityTest {

}
```

## 什么是Shadow类
Shadow是Robolectric的立足之本，如其名，作为影子，一定是变幻莫测，时有时无，且依存于本尊。Robolectric定义了大量模拟Android系统类行为的Shadow类，当这些系统类被创建的时候，Robolectric会查找对应的Shadow类并创建一个Shadow类与原始类关联。每当系统类的方法被调用的时候，Robolectric会保证Shadow对应的方法会调用。这些Shadow对象，丰富了本尊的行为，能更方便的对Android相关的对象进行测试。
比如，我们可以借助ShadowActivity验证页面是否正确跳转了
```java
    /**
     * 验证点击事件是否触发了页面跳转，验证目标页面是否预期页面
     *
     * @throws Exception
     */
    @Test
    public void testJump() throws Exception {
        // 默认会调用Activity的生命周期: onCreate->onStart->onResume
        MainActivity activity = Robolectric.setupActivity(MainActivity.class);
        // 触发按钮点击
        activity.findViewById(R.id.activity_main_jump).performClick();

        // 获取对应的Shadow类
        ShadowActivity shadowActivity = Shadows.shadowOf(activity);
        // 借助Shadow类获取启动下一Activity的Intent
        Intent nextIntent = shadowActivity.getNextStartedActivity();
        // 校验Intent的正确性
        assertEquals(nextIntent.getComponent().getClassName(), SecondActivity.class.getName());
    }
```

## @Config配置
可以通过`@Config`定制Robolectric的运行时的行为。这个注解可以用来注释类和方法，如果类和方法同时使用了@Config，那么方法的设置会覆盖类的设置。你可以创建一个基类，用@Config配置测试参数，这样，其他测试用例就可以共享这个配置了

## 配置SDK版本
Robolectric会根据manifest文件配置的targetSdkVersion选择运行测试代码的SDK版本，如果你想指定sdk来运行测试用例，可以通过下面的方式配置
```java
@Config(sdk = Build.VERSION_CODES.JELLY_BEAN)
public class SandwichTest {

    @Config(sdk = Build.VERSION_CODES.KITKAT)
    public void getSandwich_shouldReturnHamSandwich() {
    }
}
```

## 配置Application类
Robolectric会根据manifest文件配置的Application配置去实例化一个Application类，如果你想在测试用例中重新指定，可以通过下面的方式配置
```java
@Config(application = CustomApplication.class)
public class SandwichTest {

    @Config(application = CustomApplicationOverride.class)
    public void getSandwich_shouldReturnHamSandwich() {
    }
}
```

## 指定Resource路径
Robolectric可以让你配置manifest、resource和assets路径，可以通过下面的方式配置
```java
@Config(manifest = "some/build/path/AndroidManifest.xml",
        assetDir = "some/build/path/assetDir",
        resourceDir = "some/build/path/resourceDir")
public class SandwichTest {

    @Config(manifest = "other/build/path/AndroidManifest.xml")
    public void getSandwich_shouldReturnHamSandwich() {
    }
}
```

## 使用第三方Library Resources
当Robolectric测试的时候，会尝试加载所有应用提供的资源，但如果你需要使用第三方库中提供的资源文件，你可能需要做一些特别的配置。不过如果你使用gradle来构建Android应用，这些配置就不需要做了，因为Gradle Plugin会在build的时候自动合并第三方库的资源，但如果你使用的是Maven，那么你需要配置libraries变量：
```java
@RunWith(RobolectricTestRunner.class)
@Config(libraries = {
    "build/unpacked-libraries/library1",
    "build/unpacked-libraries/library2"
})
public class SandwichTest {
}
```

## 使用限定的资源文件
Android会在运行时加载特定的资源文件，如根据设备屏幕加载不同分辨率的图片资源、根据系统语言加载不同的string.xml，在Robolectric测试当中，你也可以进行一个限定，让测试程序加载特定资源.多个限定条件可以用破折号拼接在在一起。
```java
    /**
     * 使用qualifiers加载对应的资源文件
     *
     * @throws Exception
     */
    @Config(qualifiers = "zh-rCN")
    @Test
    public void testString() throws Exception {
        final Context context = RuntimeEnvironment.application;
        assertThat(context.getString(R.string.app_name), is("单元测试Demo"));
    }
```

## Properties文件
如果你嫌通过注解配置上面的东西麻烦，你也可以把以上配置放在一个Properties文件之中，然后通过@Config指定配置文件，比如，首先创建一个配置文件robolectric.properties:
```
# 放置Robolectric的配置选项:
sdk=21
manifest=some/build/path/AndroidManifest.xml
assetDir=some/build/path/assetDir
resourceDir=some/build/path/resourceDir
```
然后把robolectric.properties文件放到src/test/resources目录下，运行的时候，会自动加载里面的配置

## 系统属性配置

 - robolectric.offline：true代表关闭运行时获取jar包
 - robolectric.dependency.dir：当处于offline模式的时候，指定运行时的依赖目录
 - robolectric.dependency.repo.id：设置运行时获取依赖的Maven仓库ID，默认是sonatype
 - robolectric.dependency.repo.url：设置运行时依赖的Maven仓库地址，默认是https://oss.sonatype.org/content/groups/public/
 - robolectric.logging.enabled：设置是否打开调试开关

以上设置可以通过Gradle进行配置，如：
```gradle
android {

    testOptions {
        unitTests.all {
            systemProperty 'robolectric.dependency.repo.url', 'https://local-mirror/repo'
            systemProperty 'robolectric.dependency.repo.id', 'local'
        }
    }
}
```

## 驱动Activity生命周期
利用`ActivityController`我们可以让Activity执行相应的生命周期方法，如：
```java
    @Test
    public void testLifecycle() throws Exception {
        // 创建Activity控制器
        ActivityController<MainActivity> controller = Robolectric.buildActivity(MainActivity.class);
        MainActivity activity = controller.get();
        assertNull(activity.getLifecycleState());

        // 调用Activity的performCreate方法
        controller.create();
        assertEquals("onCreate", activity.getLifecycleState());

        // 调用Activity的performStart方法
        controller.start();
        assertEquals("onStart", activity.getLifecycleState());

        // 调用Activity的performResume方法
        controller.resume();
        assertEquals("onResume", activity.getLifecycleState());

        // 调用Activity的performPause方法
        controller.pause();
        assertEquals("onPause", activity.getLifecycleState());

        // 调用Activity的performStop方法
        controller.stop();
        assertEquals("onStop", activity.getLifecycleState());

        // 调用Activity的performRestart方法
        controller.restart();
        // 注意此处应该是onStart，因为performRestart不仅会调用restart，还会调用onStart
        assertEquals("onStart", activity.getLifecycleState());

        // 调用Activity的performDestroy方法
        controller.destroy();
        assertEquals("onDestroy", activity.getLifecycleState());
    }
```
通过ActivityController，我们可以模拟各种生命周期的变化。但是要注意，我们虽然可以随意调用Activity的生命周期，但是Activity生命周期切换有自己的检测机制，我们要遵循Activity的生命周期规律。比如，如果当前Activity并非处于stop状态，测试代码去调用了controller.restart方法，此时Activity是不会回调onRestart和onStart的。

除了控制生命周期，还可以在启动Activity的时候传递Intent：
```java
    /**
     * 启动Activity的时候传递Intent
     *
     * @throws Exception
     */
    @Test
    public void testStartActivityWithIntent() throws Exception {
        Intent intent = new Intent();
        intent.putExtra("test", "HelloWorld");
        Activity activity = Robolectric.buildActivity(MainActivity.class).withIntent(intent).create().get();
        assertEquals("HelloWorld", activity.getIntent().getExtras().getString("test"));
    }
```

onRestoreInstanceState回调中传递Bundle：
```java
    /**
     * savedInstanceState会在onRestoreInstanceState回调中传递给Activity
     *
     * @throws Exception
     */
    @Test
    public void testSavedInstanceState() throws Exception {
        Bundle savedInstanceState = new Bundle();
        Robolectric.buildActivity(MainActivity.class).create().restoreInstanceState(savedInstanceState).get();
        // verify something
    }
```

在真实环境下，视图是在onCreate之后的某一时刻在attach到Window上的，在此之前，View是处于不可操作状态的，你不能点击它。在Activity的onPostResume方法调用之后，View才会attach到Window之中。但是，在Robolectric之中，我们可以用控制器的`visible`方法使得View变为可见，变为可见之后，就可以模拟点击事件了
```java
    @Test
    public void testVisible() throws Exception {
        ActivityController<MainActivity> controller = Robolectric.buildActivity(MainActivity.class);
        MainActivity activity = controller.get();

        // 调用Activity的performCreate并且设置视图visible
        controller.create().visible();
        // 触发点击
        activity.findViewById(R.id.activity_main_button1).performClick();

        // 验证
        assertEquals(shadowOf(activity).getNextStartedActivity().getComponent().getClassName(), SecondActivity.class.getName());
    }
```

## 追加模块
为了减少依赖包的大小，Robolectric的shadows类成了好几部分：

| SDK Package | Robolectric Add-On Package |
| --------| ----- |
| com.android.support.support-v4 | org.robolectric:shadows-support-v4 |
| com.android.support.multidex | org.robolectric:shadows-multidex |
| com.google.android.gms:play-services | org.robolectric:shadows-play-services |
| com.google.android.maps:maps | org.robolectric:shadows-maps |
| org.apache.httpcomponents:httpclient | org.robolectric:shadows-httpclient |

用户可以根据自身需求添加以下依赖包，如
```gradle
dependencies {
    ... ...
    testCompile 'org.robolectric:robolectric:3.1.4'
    testCompile 'org.robolectric:shadows-support-v4:3.1.4'
    testCompile 'org.robolectric:shadows-multidex:3.1.4'
    testCompile 'org.robolectric:shadows-play-services:3.1.4'
    testCompile 'org.robolectric:shadows-maps:3.1.4'
    testCompile 'org.robolectric:shadows-httpclient:3.1.4'
}

```

## 自定义Shadow类
 1. Shadow类需要一个public的无参构造方法以方便Robolectric框架可以实例化它，通过@Implements注解与原始类关联在一起
 2. 若原始类有`有参构造方法`，在Shadow类中定义public void类型的名为`__constructor__`的方法，且方法参数与原始类的构造方法参数一直
 3. 定义与原始类方法签名一致的方法，在里面重写实现，Shadow方法需用@Implementation进行注解

下面我们来创建RobolectricBean的Shadow类
原始类：
```java
public class RobolectricBean {

    String name;
    int    color;

    public RobolectricBean(String name) {
        this.name = name;
    }

    public String getName() {
        return name;
    }

    public int getColor() {
        return color;
    }

    public void setColor(int color) {
        this.color = color;
    }
}
```
Shadow类:
```java
/**
 * 创建{@link RobolectricBean}的影子类
 *
 * @author HansChen
 */
@Implements(RobolectricBean.class)
public class ShadowRobolectricBean {

    /**
     * 通过@RealObject注解可以访问原始对象，但注意，通过@RealObject注解的变量调用方法，依然会调用Shadow类的方法，而不是原始类的方法
     * 只能用来访问原始类的field
     */
    @RealObject
    RobolectricBean realBean;

    /**
     * 需要一个无参构造方法
     */
    public ShadowRobolectricBean() {

    }

    /**
     * 对应原始类的构造方法
     *
     * @param name 对应原始类构造方法的传入参数
     */
    public void __constructor__(String name) {
        realBean.name = name;
    }

    /**
     * 原始对象的方法被调用的时候，Robolectric会根据方法签名查找对应的Shadow方法并调用
     */
    @Implementation
    public String getName() {
        return "Hello, I ma shadow of RobolectricBean: " + realBean.name;
    }

    @Implementation
    public int getColor() {
        return realBean.color;
    }

    @Implementation
    public void setColor(int color) {
        realBean.color = color;
    }
}
```

## Shadow类中访问原始类的field
Shadow类中可以定义一个原始类的成员变量，并用@RealObject注解，这样，Shadow类就能访问原始类的field了，但是注意，通过@RealObject注解的变量调用方法，依然会调用Shadow类的方法，而不是原始类的方法，只能用它来访问原始类的field。
```java
@Implements(Point.class)
public class ShadowPoint {
    @RealObject private Point realPoint;
    ...
    public void __constructor__(int x, int y) {
        realPoint.x = x;
        realPoint.y = y;
    }
}
```

## 如何在测试用例中让Shadow生效
在Config注解中添加`shadows`参数，指定对应的Shadow生效
```java
@RunWith(RobolectricTestRunner.class)
@Config(shadows = ShadowRobolectricBean.class)
public class RobolectricBeanTest {

    ... ...
}
```
注意，自定义的Shadow类不能通过`Shadows.shadowOf()`获取，需要用`ShadowExtractor.extract()`来获取，获取之后进行类型转换:
```java
ShadowRobolectricBean shadowBean = (ShadowRobolectricBean) ShadowExtractor.extract(bean);
```

# 常用测试场景
## 页面跳转验证
```java
    /**
     * 验证点击事件是否触发了页面跳转，验证目标页面是否预期页面
     *
     * @throws Exception
     */
    @Test
    public void testJump() throws Exception {
        // 默认会调用Activity的生命周期: onCreate->onStart->onResume
        MainActivity activity = Robolectric.setupActivity(MainActivity.class);
        // 触发按钮点击
        activity.findViewById(R.id.activity_main_jump).performClick();

        // 获取对应的Shadow类
        ShadowActivity shadowActivity = Shadows.shadowOf(activity);
        // 借助Shadow类获取启动下一Activity的Intent
        Intent nextIntent = shadowActivity.getNextStartedActivity();
        // 校验Intent的正确性
        assertEquals(nextIntent.getComponent().getClassName(), SecondActivity.class.getName());
    }
```

## UI组件状态验证
```java
    /**
     * 验证UI组件状态
     *
     * @throws Exception
     */
    @Test
    public void testCheckBoxState() throws Exception {
        MainActivity activity = Robolectric.setupActivity(MainActivity.class);
        CheckBox checkBox = (CheckBox) activity.findViewById(R.id.activity_main_check_box);
        // 验证CheckBox初始状态
        assertFalse(checkBox.isChecked());

        // 点击按钮反转CheckBox状态
        activity.findViewById(R.id.activity_main_switch_check_box).performClick();
        // 验证状态是否正确
        assertTrue(checkBox.isChecked());

        // 点击按钮反转CheckBox状态
        activity.findViewById(R.id.activity_main_switch_check_box).performClick();
        // 验证状态是否正确
        assertFalse(checkBox.isChecked());
    }
```

## 验证Dialog
```java
    /**
     * 验证Dialog是否正确弹出
     *
     * @throws Exception
     */
    @Test
    public void testDialog() throws Exception {
        MainActivity activity = Robolectric.setupActivity(MainActivity.class);
        AlertDialog dialog = ShadowAlertDialog.getLatestAlertDialog();
        // 判断Dialog尚未弹出
        assertNull(dialog);

        activity.findViewById(R.id.activity_main_show_dialog).performClick();
        dialog = ShadowAlertDialog.getLatestAlertDialog();
        // 判断Dialog已经弹出
        assertNotNull(dialog);
        // 获取Shadow类进行验证
        ShadowAlertDialog shadowDialog = shadowOf(dialog);
        assertEquals("AlertDialog", shadowDialog.getTitle());
        assertEquals("Oops, now you see me ~", shadowDialog.getMessage());
    }
```

## 验证Toast
```java
    /**
     * 验证Toast是否正确弹出
     *
     * @throws Exception
     */
    @Test
    public void testToast() throws Exception {
        MainActivity activity = Robolectric.setupActivity(MainActivity.class);
        Toast toast = ShadowToast.getLatestToast();
        // 判断Toast尚未弹出
        assertNull(toast);

        activity.findViewById(R.id.activity_main_show_toast).performClick();
        toast = ShadowToast.getLatestToast();
        // 判断Toast已经弹出
        assertNotNull(toast);
        // 获取Shadow类进行验证
        ShadowToast shadowToast = shadowOf(toast);
        assertEquals(Toast.LENGTH_SHORT, shadowToast.getDuration());
        assertEquals("oops", ShadowToast.getTextOfLatestToast());
    }
```

## 验证Fragment
```java
@RunWith(RobolectricTestRunner.class)
@Config(constants = BuildConfig.class, application = CustomApplication.class)
public class MyFragmentTest {

    private MyFragment myFragment;

    @Before
    public void setUp() throws Exception {
        myFragment = new MyFragment();
        // 把Fragment添加到Activity中
        FragmentTestUtil.startFragment(myFragment);
    }

    @Test
    public void testFragment() throws Exception {
        assertNotNull(myFragment.getView());
    }
}
```

## 验证BroadcastReceiver
首先看下广播接收器：
```java
public class MyReceiver extends BroadcastReceiver {
    @Override
    public void onReceive(Context context, Intent intent) {
        // do something
    }
}
```

广播的测试点可以包含两个方面

 1. 验证应用程序是否注册了该广播
 2. 验证广播接收器的处理逻辑是否正确，关于逻辑是否正确，可以直接人为的触发onReceive()方法，让然后进行验证


```java
@RunWith(RobolectricTestRunner.class)
@Config(constants = BuildConfig.class, application = CustomApplication.class)
public class MyReceiverTest {


    @Test
    public void restRegister() throws Exception {
        ShadowApplication shadowApplication = ShadowApplication.getInstance();

        String action = "ut.cn.unittestdemo.receiver";
        Intent intent = new Intent(action);

        // 验证是否注册了相应的Receiver
        assertTrue(shadowApplication.hasReceiverForIntent(intent));
    }

    @Test
    public void restReceive() throws Exception {

        String action = "ut.cn.unittestdemo.receiver";
        Intent intent = new Intent(action);
        intent.putExtra("EXTRA_USERNAME", "HansChen");

        MyReceiver myReceiver = new MyReceiver();
        myReceiver.onReceive(RuntimeEnvironment.application, intent);
        // verify something
    }
}
```

## 验证Service
Service和Activity一样，都有生命周期，Robolectric也提供了Service的生命周期控制器，使用方式和Activity类似，这里就不做详细解释了
```java
@RunWith(RobolectricTestRunner.class)
@Config(constants = BuildConfig.class, application = CustomApplication.class)
public class TestServiceTest {

    private ServiceController<TestService> controller;
    private TestService                    testService;

    @Before
    public void setUp() throws Exception {
        controller = Robolectric.buildService(TestService.class);
        testService = controller.get();
    }

    /**
     * 控制Service生命周期进行验证
     *
     * @throws Exception
     */
    @Test
    public void testLifecycle() throws Exception {

        controller.create();
        // verify something

        controller.startCommand(0, 0);
        // verify something

        controller.bind();
        // verify something

        controller.unbind();
        // verify something

        controller.destroy();
        // verify something
    }
}
```