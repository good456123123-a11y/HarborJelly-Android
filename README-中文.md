# Harbor Jelly — 安卓原生 3D 果冻港口（第一版工程）

这是原创、离线的 Godot 4.4.1 安卓游戏工程，参考用户提供的「Harbor Jelly」视频截图的**美术气氛**，不是作者的原始源码或提示词。全场景由 GDScript 程序生成；不下载素材，没有付费模型、网络请求或私有 API。

## 已经写进工程的内容

- 一块 24 × 17.5 单位的大型半透明蓝绿色果冻海洋；GPU Shader 产生流动波纹和手指触摸后传播、衰减的弹性涟漪。
- L 型港口岸壁、海边彩色小镇、30 多栋独立房屋、小树、护栏、码头、石头防波堤、灯塔。
- 成排集装箱、三台大型岸桥吊机、货轮、小型帆船、拖船、木栈桥。
- 手指触摸果冻触发波纹；手指拖动可转动场景；双指捏合缩放；船只随水面漂浮；航行暂停/继续；波纹强度滑块；重置相机视角。
- 横屏场景，专门采用相对兼容的 Godot GL Compatibility 渲染方式，面向安卓 ARM64 手机。

**注意**：这是第一次提交的源代码工程，尚未在真机或 GitHub Actions 上实际成功构建/运行验证；不能称为已经完成的 APK。你看到的原视频质感需要后续调试模型比例、材质折射和性能。工程里的 `HORN` 当前只有水纹和白色气团视觉反馈，还没有加鸣笛音效。

## 如何在 GitHub 上生成 APK（手机也能操作）

1. 在 GitHub 新建一个仓库，比如 `harbor-jelly-android`，设置公开或私有均可。
2. 下载本工程 ZIP，**解压以后**把里面的 `project.godot`、`scripts/`、`scenes/`、`shaders/`、`export_presets.cfg` 和 `.github/workflows/android-apk.yml` 上传到仓库的**根目录**。注意不要多套一层文件夹，也不要漏掉 `.github` 隐藏文件夹。
3. 提交到仓库 `main` 分支；Github Actions 的工作流将自动启动，也可以进入 Actions → `Build Harbor Jelly Android APK` → Run workflow 手动触发。
4. 若工作流成功，进入这次运行的页面，在底部 **Artifacts** 下载 `HarborJelly-Android-debug-APK.zip`，解压获得 `HarborJelly-debug.apk`。
5. 在小米手机上安装 APK，必要时允许浏览器或文件管理器“安装未知应用”。这是自用的调试包，不必使用 Google Play。

如遇到红色叉号，把 Actions 的报错日志发过来，我们根据**具体第一条错误**修改，不盲目反复重做。

## 项目结构

```
project.godot                  主配置，横屏，GL Compatibility
scenes/main.tscn               启动场景
scripts/harbor.gd              程序化建模、相机手势和交互
shaders/jelly.gdshader         GPU 果冻水面 Shader
export_presets.cfg             安卓 debug APK 出包参数
.github/workflows/android-apk.yml    GitHub Actions 自动打包
```

## 与原版的区别及后续方向

这次先把完整场景和果冻交互同时搭起来，而不是仅有一块空荡荡的果冻。海面波纹采用 GPU 解析弹性波，而不是完整的有限元物理模拟。下一次迭代可以继续优化更厚实的凝胶折射/次表面观感、泡沫船尾轨迹、更细致的模型以及低端手机帧率。

资源：Godot 引擎 4.4 文档：https://docs.godotengine.org/en/4.4/ 。Godot CI：https://github.com/aBARICHELLO/godot-ci 。
