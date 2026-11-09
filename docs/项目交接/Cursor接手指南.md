# 《苏七镇奇缘》Cursor 接手指南

> 给用 Cursor 的朋友。先读同目录的《项目交接文档.md》（游戏是什么、仓库分支、工位分工）和《项目节奏表.md》，再读本文件：本文件只讲"在 Cursor 里怎么上手、怎么不踩坑、现在该做什么"。
> 项目是阿鱼的个人非商业小游戏，阿鱼拍板，剧情不许自己编。

## 一、5 分钟上手

1. 打开仓库 `planbforayu/changhong-village`，分支 `hongyuan-launch`（唯一主线）。
2. 装 Godot 4.7.2（兼容渲染模式），把 `godot` 命令放进 PATH。
3. 终端：
   ```sh
   git fetch origin hongyuan-launch
   git checkout -b <你的短分支> origin/hongyuan-launch
   cd godot && godot --headless --import
   GODOT=godot ./hongyuan/tests/run_all.sh
   ```
   记下主线原本就失败的测试项（call_hold、content_loader、fishing_cast、gui_input、office、p0_fix、pandas、pandas_touch、phone_layout、shanghai_controls、world_scale、scenes_walkthrough），之后只看有没有新增失败。
4. 想看效果：打开网页版 <https://kayrashuai1900-alt.github.io/love_in_su7/>，链接后加 `?new=1` 清档从头玩一遍；或用 Godot 编辑器打开 `godot/project.godot` 直接运行。

## 二、给 Cursor 的上下文（建议建 `.cursor/rules/hongyuan.mdc`）

把下面这段放进规则文件，让 Cursor 每次都带着它：

```
这是 Godot 4.7.2 / GDScript 项目，微信小游戏 + 网页版。入口是 godot/hongyuan/boot.tscn。
爱情篇章节内容是 JSON 数据驱动：godot/hongyuan/chapters/*.json（旁白、对白、热点、小游戏步骤），
玩家看到的字在 godot/hongyuan/copy.json（键名如 A3-2d），部分提示写死在 games/*.gd、ui/*.gd 里。
改字优先改 copy.json，不要在代码里加新的中文字符串。
规则：
- 一张卡一个 PR，base 是 hongyuan-launch，不要直接提交到它，也不要叠 PR。
- 不自己编剧情或改对白，以 docs/红缘原稿/ 和阿鱼给的文案定稿为准；地名一律写"苏七镇"。
- 小游戏没有失败、没有分数，失误只重来一次；不做章末卡/领奖页/选章页；前六章旁白不用第一人称。
- 微信里不能从显卡读回数据：禁用 get_image、surface_get_arrays 等（电脑上测不出来，真机会崩）。
- 所有美术图都由 GPT 出，代码生成或自己改的图不要提交；新图放 godot/hongyuan/assets/_inbox/，不要直接放正式路径，_inbox 的 .import 不要提交。
- 新图放进 assets 后先跑 godot --headless --import；换背景要检查可走区域、热点和旧人物站位。
- 不提交密钥、AppSecret、账号信息；上传、部署、改小游戏后台、花钱之前先问阿鱼。
- 提交前跑 GODOT=godot ./hongyuan/tests/run_all.sh，只确认没有新增失败。
```

## 三、Cursor 里常用的工作方式

- **找文案**：全局搜键名（如 `A3-2d`）或中文原句；`copy.json` 是主要来源，其次 `chapters/*.json` 的目标卡（目标/操作/所得），最后才是 `.gd` 里写死的字。
- **改一个场景**：先看对应 `chapters/<章>.json` 里的 step 与 beat，再看 `scene_runner.gd` 怎么执行，小游戏看 `games/<名>.gd`。让 Cursor 先读这三处再改。
- **接新图**：把 GPT 交的图放进 `assets` 对应目录 → `godot --headless --import` → 在场景/JSON 里改引用 → 检查可走区域、热点、actors。
- **出包**：网页版用 `godot/hongyuan/tools/export_web.py`、`split_web_pack.py`、`pages_site.py`；小程序要在阿鱼的 Mac 上跑 `export_wechat.py`（见 `tools/WECHAT.md`），上传云存储和预览码都由阿鱼本人操作，别自己去做。
- 不会跑 Godot 编辑器也能做：改 JSON、改 `.gd`、读测试结果；需要看画面时让阿鱼或另一位同事截图。

## 四、现在最该做的事（阿鱼 2026-11-09 验收意见，爱情篇）

完整原文在项目共享文件夹 `爱情篇/` 下，请先读这三份（向阿鱼或项目成员要）：
1. `爱情篇修改意见清单-1109.md`：截图序号 1–21 逐条意见 + 整体体验。
2. `爱情篇文案定稿-1109.md`：全部 205 条文案定稿，含请柬、章末过渡页、来电微信对话、群聊、粤语招牌、目标栏文案。
3. `给GPT-爱情篇改图指令-1109.md`：要 GPT 出的图，出了之后由你接。

代码侧要点（建议按这个顺序拆成独立 PR）：
1. **文案替换**：按定稿改 `copy.json`，含新增键；统一称呼"邀请函/收件人/Offer/Toretto"。
2. **请柬**：第 4 张按定稿排版（亲爱的我的朋友【玩家名】…时间：永远有效）。
3. **左上角目标栏**：每关常驻，显示核心目标和进度（如"喂饱熊猫 0/3"），目标提示比现在上方的横条更显眼。
4. **NPC 行为**：不重叠、不互相碾压、放慢速度、只在可走区域活动（不踩水、不上桌）；船内 NPC 静止；阿晓的车沿马路开，不穿过人群广场。
5. **来电章流程**：接电话 → 按住听 → 切微信对话页（用截图16的微信模板）→ 回阿鱼房间展示他心里能改变的部分；其余微信对话统一用这个模板，群聊底图用截图21。
6. **关卡玩法提示**：压力条提示"点下方进度条"（工作/家庭/爱情）；烦恼泡泡加爱心引导，让人知道往上点。
7. **对话框**：名字放头像下方，不挡对话。
8. **章末过渡页**：每章 2 页（大字+小字），淡入淡出，点击翻页。
9. **背景音乐**：6 段不同曲子对应不同场景，素材由阿鱼提供或确认。
10. **接新图**：选角整体卡、收信场景、请柬底图、码头栈桥重画、香港粤语招牌、各场景比例修正；等 GPT 交图。

## 五、协作与验收

- 交接靠仓库：看板在 `回执/W2工位/看板.md`（爱情篇）。做完一张卡就在看板上记一行并开 PR。
- Claude 负责审 PR；合并前自己先跑测试，并在 PR 描述里写清楚"改了什么、怎么验证、有无新增失败"。
- 和阿鱼最新的话冲突时，以阿鱼为准；两份文档冲突时，以日期新的为准。
- 有拿不准的画面或文案，不要自己拍板，列成问题交给阿鱼。

## 六、不要做的事

- 不在 `hongyuan-launch` 上直接提交，不往旧分支上提交。
- 不自己编剧情、不改对白。
- 不提交密钥和账号信息。
- 不删别人的文件；共享文件夹只加不删。
- 不用代码生成美术图。
