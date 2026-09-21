# 发版操作手册（已迁移）

> 本文件曾与后端仓库 `gv_im_server/docs/RELEASE_RUNBOOK.md` 保持一致，但现已停用，避免两处内容漂移、互相矛盾。

**客户端发版（Android 直装 APK）请看唯一权威文档：**

- 发版 Skill（一步步怎么做 + 快捷脚本）：`gv_im_server/docs/standards/15_CLIENT_RELEASE_SKILL.md`
- 打包命令权威来源：本仓库 `BUILD.md`
- 后端/管理后台/官网部署：`gv_im_server/docs/RELEASE_RUNBOOK.md`

**快捷脚本**：

```powershell
cd D:\projects\cnb\gv_chat_app
.\tools\release.ps1 -ReleaseNotes "更新说明"
```
