/// Edge WebView2 无 [JavaScriptChannel]，在文档内将 `GVBridge.postMessage` 接到
/// [window.chrome.webview.postMessage]；须早于 [gvMiniProgramSdkBootstrap] 执行（如
/// [WebviewController.addScriptToExecuteOnDocumentCreated]）。
const String gvMiniProgramWebView2BridgeShim = '''
(function(){
  if (window.chrome && window.chrome.webview && !window.GVBridge) {
    window.GVBridge = {
      postMessage: function(msg) {
        window.chrome.webview.postMessage(typeof msg === 'string' ? msg : JSON.stringify(msg));
      }
    };
  }
})();
''';

/// 修补 Flutter WebKit 注入的 `window.GVBridge = webkit.messageHandlers...`：
/// 在部分 iOS 环境下裸 `webkit` 非全局会导致整段 user script 失败，[GVBridge] 未定义。
/// 在跑主引导前执行本段，用 [window.webkit] 补挂 [GVBridge]。
const String gvMiniProgramGvBridgeRepairShim = '''
(function(){
  try {
    if (window.GVBridge && typeof window.GVBridge.postMessage === 'function') return;
    var mh = window.webkit && window.webkit.messageHandlers &&
        window.webkit.messageHandlers.GVBridge;
    if (mh && typeof mh.postMessage === 'function') {
      window.GVBridge = { postMessage: function(m) { mh.postMessage(m); } };
    }
  } catch (e) {}
})();
''';

/// 注入到 H5 的引导脚本：注册 `window.OPEN_SDK` 与 `GVBridge` 的 Promise 桥。
///
/// 保持与历史行为一致，仅抽离为独立常量便于主组件阅读。
const String gvMiniProgramSdkBootstrap = '''
(function(){
  if (!window.__open_sdk_boot) {
    window.__open_sdk_boot = true;
    var pending = {};
    window.__gvResolve = function(id, jsonStr) {
      var p = pending[id];
      if (p) delete pending[id];
      if (!p) return;
      try {
        var o = JSON.parse(jsonStr);
        if (o.__error) p.reject(new Error(o.__error));
        else p.resolve(o.__result);
      } catch (e) { p.reject(e); }
    };
    function postToHost(s) {
      if (window.GVBridge && typeof window.GVBridge.postMessage === 'function') {
        window.GVBridge.postMessage(s);
        return;
      }
      var mh = window.webkit && window.webkit.messageHandlers &&
          window.webkit.messageHandlers.GVBridge;
      if (mh && typeof mh.postMessage === 'function') {
        mh.postMessage(s);
        return;
      }
      throw new Error('GVBridge unavailable');
    }
    function invoke(method) {
      return new Promise(function(resolve, reject) {
        var id = 'open_' + Date.now() + '_' + Math.random().toString(36).slice(2, 11);
        pending[id] = { resolve: resolve, reject: reject };
        try {
          postToHost(JSON.stringify({ id: id, method: method }));
        } catch (e) {
          delete pending[id];
          reject(e);
        }
      });
    }
    window.OPEN_SDK = {
      getUserGID: function() { return invoke('getUserGID'); },
      getUserPhone: function() { return invoke('getUserPhone'); },
      getUserEmail: function() { return invoke('getUserEmail'); },
      getLocation: function() { return invoke('getLocation'); },
      enterApp: function() { return invoke('enterApp'); },
      exitApp: function() { invoke('exitApp'); }
    };
  }
  try {
    window.dispatchEvent(new CustomEvent('gv-sdk-ready', { detail: { v: 1 } }));
  } catch (e) {}
})();
''';
