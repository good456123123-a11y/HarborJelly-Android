# Harbor Jelly · 安卓 3D 果冻港口

这是 Godot 4.4.1 的安卓横屏原型，场景包括可触摸的果冻海面、彩色海港小镇、码头、船只、吊机、集装箱和灯塔。

**状态：源工程已提交；APK 编译与手机实测结果尚未确认。**

## 安卓手机获取测试 APK

1. 打开 [Actions 自动构建页面](https://github.com/good456123123-a11y/HarborJelly-Android/actions/workflows/android-apk.yml)。
2. 打开最新一次 **Build Harbor Jelly Android APK** 构建记录。如果没有记录，可点击 **Run workflow** 手动触发。
3. 只有显示绿色对勾，才能进入该记录的 **Artifacts** 下载 `HarborJelly-Android-debug-APK`。
4. 解压下载到手机的 ZIP，安装其中的 `HarborJelly-debug.apk`。如有红色叉号，需先看日志修复，不能认作已成功编译。

## 工程内容

`harbor-source.tar.xz.b64` 是完整源码的压缩文本；GitHub Actions 自动解码并展开为 `project.godot`、`scripts/harbor.gd`、`scenes/main.tscn`、`shaders/jelly.gdshader`、`export_presets.cfg` 和中文说明文件，随后尝试导出安卓调试 APK。工作流也会尝试把解压后的代码提交回仓库以便直接浏览。

原型用程序生成模型，没有下载资源或外部 CDN，果冻海面以 GPU 着色器模拟波纹和弹性；它不是原网页作者的源码。效果和性能需要手机实际测试。

> 这是第一版实验代码，未经设备端验证，不保证首次编译成功。
