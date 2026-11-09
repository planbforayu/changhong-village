"""把 Godot Web 导出改成能放 GitHub Pages 的静态站：.pck 拆成 45MB 一块（GitHub 单文件上限 100MB），
页面里按顺序流式拼回，加载进度照常走。用法：python3 pages_site.py <导出目录> <站点目录> [提交号]"""
import json, re, shutil, sys
from pathlib import Path

src, dst = Path(sys.argv[1]), Path(sys.argv[2])
build = sys.argv[3] if len(sys.argv) > 3 else ""
STEP = 45 * 1024 * 1024
for old in dst.glob("index.pck.*"):
    old.unlink()
for name in ["index.html", "index.js", "index.wasm", "index.audio.worklet.js", "index.audio.position.worklet.js",
             "index.png", "index.icon.png", "index.apple-touch-icon.png"]:
    shutil.copyfile(src / name, dst / name)
data = (src / "index.pck").read_bytes()
sizes = []
for i in range(0, len(data), STEP):
    part = data[i:i + STEP]
    (dst / ("index.pck.%d" % len(sizes))).write_bytes(part)
    sizes.append(len(part))
patch = """<script>
(function(){const f=window.fetch.bind(window),SIZES=%s,TOTAL=%d;
window.fetch=function(i,o){const u=typeof i==='string'?i:(i&&i.url)||'';
if(!/index\\.pck(\\?|$)/.test(u))return f(i,o);
let k=0,reader=null;
const body=new ReadableStream({async pull(c){
for(;;){if(!reader){if(k>=SIZES.length){c.close();return;}const r=await f('index.pck.'+k+'?v=%s');if(!r.ok)throw new Error('pck '+k+' '+r.status);reader=r.body.getReader();}
const x=await reader.read();if(x.done){reader=null;k++;continue;}c.enqueue(x.value);return;}}});
return Promise.resolve(new Response(body,{headers:{'Content-Type':'application/octet-stream','Content-Length':String(TOTAL)}}));};})();
</script>
<script src="index.js"></script>""" % (json.dumps(sizes), len(data), build)
html = (dst / "index.html").read_text()
assert '<script src="index.js"></script>' in html
html = html.replace('<script src="index.js"></script>', patch, 1)
html = re.sub(r'"index\.pck":\d+', '"index.pck":%d' % len(data), html)
if build:
    html = html.replace("</head>", '<meta name="hongyuan-build" content="%s"></head>' % build, 1)
(dst / "index.html").write_text(html)
(dst / ".nojekyll").touch()
# 按章下载：content/ 里是带内容哈希的章节包，只保留这次清单里用到的。
content = dst / "content"
if (src / "content").is_dir():
    content.mkdir(exist_ok=True)
    keep = {p.name for p in (src / "content").iterdir()}
    for old in content.iterdir():
        if old.name not in keep:
            old.unlink()
    for part in (src / "content").iterdir():
        if not (content / part.name).exists():
            shutil.copyfile(part, content / part.name)
    print("content", len(keep), sum(p.stat().st_size for p in content.iterdir()))
elif content.is_dir():
    shutil.rmtree(content)
print("parts", sizes)
