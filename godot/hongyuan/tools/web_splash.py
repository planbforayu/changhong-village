"""给爱情篇 Web 加载页换上开屏图：图片写在 HTML 里，index.js、.wasm、.pck 还没下载时就先显示。"""
import shutil
from pathlib import Path

SPLASH = Path(__file__).resolve().parents[1] / "assets/round1/common/splash_1108.png"
MARK = "<!-- hongyuan-splash -->"
STYLE = MARK + """<style>
#status{visibility:visible;background-color:#48223a}
#status-splash{top:0;bottom:auto;left:0;right:0;margin:0 auto;width:min(100vw,56.25vh);height:auto;max-width:none;max-height:none;object-fit:contain;image-rendering:pixelated}
#status-progress{bottom:calc(9% + env(safe-area-inset-bottom,0px));width:min(60vw,320px);accent-color:#e7b65c}
#hy-loading{position:absolute;left:0;right:0;bottom:calc(9% + env(safe-area-inset-bottom,0px) + 28px);text-align:center;color:#f3dfc8;font:16px/1.4 "PingFang SC","Noto Sans SC",sans-serif;letter-spacing:.08em}
</style>
"""


def apply(out: Path) -> None:
    """out 是 Godot Web 导出目录。重复执行不会叠加。"""
    shutil.copyfile(SPLASH, out / "index.png")
    html = out / "index.html"
    text = html.read_text()
    if MARK in text:
        return
    if "</head>" not in text or '<progress id="status-progress"></progress>' not in text:
        raise SystemExit("index.html 结构变了，开屏图没接上")
    text = text.replace("</head>", STYLE + "</head>", 1)
    text = text.replace('<progress id="status-progress"></progress>',
                        '<div id="hy-loading">红缘大冒险 · 正在加载</div>\n\t\t\t<progress id="status-progress"></progress>', 1)
    html.write_text(text)


if __name__ == "__main__":
    import sys
    apply(Path(sys.argv[1]))
