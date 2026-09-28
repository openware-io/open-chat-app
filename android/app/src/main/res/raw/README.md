# 自定义 Android 信任根

`network_security_config.xml` 只在本目录存在 `sectigo_r46.pem` 时额外信任该证书。
该文件由受控发布流程或本机配置注入，不能提交真实证书材料。

开发环境如不需要兼容旧 Android 的额外信任根，可删除 `network_security_config.xml` 中
`@raw/sectigo_r46` 对应的 `<certificates>` 行后构建。
