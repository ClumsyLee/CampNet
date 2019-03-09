---
# Feel free to add content and custom Front Matter to this file.
# To modify the layout, see https://jekyllrb.com/docs/themes/#overriding-theme-defaults

layout: home
---

<section class="title-section">
# 全自动校园网助手
## 为更多人设计的校园网 iOS 客户端。
[![在 App Store 下载 CampNet](/imgs/Download_on_the_App_Store_Badge_CNSC_RGB_blk_092917.svg){:class="app-store-button"}](https://itunes.apple.com/app/campnet/id1263284287?mt=8)

![总览页面](/imgs/overview-zh-hans@1x.jpg){:srcset="/imgs/overview-zh-hans@2x.jpg 2x, /imgs/overview-zh-hans@3x.jpg 3x"}
</section>

<section class="feature-section">
<div class="wrapper">
## 全自动
连上 Wi-Fi 就会自动登录，真正做到全自动。

无论是从宿舍到教室，还是从图书馆到食堂，无论网络环境如何变化，你都不需要手动打开网页上线。再也不需要因为校园网而分心了，它一直都在。
</div>
</section>

<section class="feature-section">
<div class="wrapper">
<div class="section-row">
<div class="section-col section-col-text">
## 流量警报
最后一刻才发现流量没了？让这种事成为历史。

CampNet 会在后台监控你的流量。一旦你的剩余流量小于特定百分比，CampNet 就会给你发送流量警报，让你提前做好规划和准备。
</div>
<div class="section-col section-col-image">
![流量警报](/imgs/usage-alert-zh-hans@1x.jpg){:srcset="/imgs/usage-alert-zh-hans@2x.jpg 2x, /imgs/usage-alert-zh-hans@3x.jpg 3x"}
</div>
</div>
</div>
</section>

<section class="feature-section">
<div class="wrapper">
<div class="section-row">
<div class="section-col section-col-text">
## 设备管理
轻松管理你的在线设备。

管理你的所有在线设备，下线其他设备，抑或是上线特定 IP。只要你的学校网络支持，CampNet 都能做到。忘掉某难用的学校网站吧。
</div>
<div class="section-col section-col-image">
![在线设备页面](/imgs/devices-zh-hans@1x.jpg){:srcset="/imgs/devices-zh-hans@2x.jpg 2x, /imgs/devices-zh-hans@3x.jpg 3x"}
</div>
</div>
</div>
</section>

<section class="feature-section">
<div class="wrapper">
<div class="section-row">
<div class="section-col section-col-text">
## 多账户支持
同时管理多个账户，多个学校也没问题。

想和舍友共享账号？想监控实验室上网账户的余额？CampNet 统统能做到。还记得刚刚说的流量警报吗？你猜对了，所有账户的流量都在监控之中。
</div>
<div class="section-col section-col-image">
![账户页面](/imgs/accounts-zh-hans@1x.jpg){:srcset="/imgs/accounts-zh-hans@2x.jpg 2x, /imgs/accounts-zh-hans@3x.jpg 3x"}
</div>
</div>
</div>
</section>

<section class="feature-section">
<div class="wrapper">
<div class="section-row">
<div class="section-col section-col-text">
## 小组件
不需要打开 app，就能查看当月流量趋势。

CampNet 的目标之一是，让用户感受不到自己的存在。但我们还想更进一步。我们希望让流量监控成为习惯，而不是负担。
</div>
<div class="section-col section-col-image">
![小组件](/imgs/widget-zh-hans@1x.jpg){:srcset="/imgs/widget-zh-hans@2x.jpg 2x, /imgs/widget-zh-hans@3x.jpg 3x"}
</div>
</div>
</div>
</section>

<section class="feature-section">
<div class="wrapper">
<div class="section-row">
<div class="section-col section-col-text">
## 可扩展
千千万万的校园网，我们支持……全部。

通用，而不是给每个校园网做一个新 app，这是 CampNet 的终极目标。我们设计了一套配置文件来描述校园网。只要添加新的配置，就能支持新的网络。

你可以加载自定义配置，但若将配置提交到 [GitHub 仓库](https://github.com/ClumsyLee/CampNet-Configurations)，你就可以让 CampNet 正式支持你的学校，让你的同学们享受你的成果。
</div>
<div class="section-col section-col-image">
![配置文件](/imgs/config-file@1x.png){:srcset="/imgs/config-file@2x.png 2x, /imgs/config-file@3x.png 3x"}
</div>
</div>
</div>
</section>


<section class="campus-request-section">
<div class="section-row">
<div class="section-col">
清华大学

![清华大学](/imgs/thu@1x.png){:srcset="/imgs/thu@2x.png 2x, /imgs/thu@3x.png 3x"}
</div>

<div class="section-col">
中国人民大学

![中国人民大学](/imgs/ruc@1x.png){:srcset="/imgs/ruc@2x.png 2x, /imgs/ruc@3x.png 3x"}
</div>

<div class="section-col">
中国科学院大学

![中国科学院大学](/imgs/ucas@1x.png){:srcset="/imgs/ucas@2x.png 2x, /imgs/ucas@3x.png 3x"}
</div>
</div>

<div>
<form id="campus-request-form">
<input id="campus-request-content" type="text" class="campus-request-input" placeholder="没有你的学校？告诉我们！">
<button id="campus-request-button" class="campus-request-submit">提交请求</button>
</form>
</div>

<script>
window.onload = function () {
  document.getElementById('campus-request-form').onsubmit = function (event) {
    event.preventDefault();
    var content = document.getElementById('campus-request-content').value;
    if (!content) return false;

    var button = document.getElementById('campus-request-button');
    if (button.disabled) return false;
    button.disabled = true;
    button.textContent = '提交中…';

    var request = new XMLHttpRequest();
    request.open('POST', 'https://campnet-campus-request.clumsy.li/requests', true);
    request.setRequestHeader('Content-Type', 'application/json');
    request.onload = function () {
      if (request.status == 201) {
        button.textContent = '已提交！';
      } else {
        button.textContent = '提交失败';
      }
      button.disabled = false;
    };
    request.onerror = function () {
      button.textContent = '提交失败';
      button.disabled = false;
    };

    request.send(JSON.stringify({ content: content }));
    return false;
  };
};
</script>

</section>
