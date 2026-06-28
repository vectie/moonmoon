from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_LEFT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import cm, mm
from reportlab.lib.utils import ImageReader
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.pdfgen import canvas
from reportlab.platypus import Paragraph

from pathlib import Path
import math
import os


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "output" / "pdf" / "moonsuite_exhibition_profile.pdf"
GENERATED_VISUAL = ROOT / "assets" / "exhibition" / "moonsuite_lunar_ops_visual.png"

FONT = "STHeiti"
FONT_PATH = Path(
    os.environ.get("MOONSUITE_EXHIBITION_FONT", "/System/Library/Fonts/STHeiti Medium.ttc")
)
if not FONT_PATH.exists():
    raise SystemExit(
        "Missing Chinese font. Set MOONSUITE_EXHIBITION_FONT to a local .ttf/.ttc path."
    )
pdfmetrics.registerFont(TTFont(FONT, str(FONT_PATH), subfontIndex=0))

COLORS = {
    "ink": colors.HexColor("#142033"),
    "muted": colors.HexColor("#5B667A"),
    "line": colors.HexColor("#D7DEE8"),
    "soft": colors.HexColor("#F3F6FA"),
    "navy": colors.HexColor("#12294A"),
    "blue": colors.HexColor("#246BFE"),
    "cyan": colors.HexColor("#09A7C8"),
    "green": colors.HexColor("#20A36B"),
    "amber": colors.HexColor("#D6912C"),
    "red": colors.HexColor("#D9564A"),
    "moon": colors.HexColor("#D9E0EA"),
    "space": colors.HexColor("#07111F"),
}


styles = getSampleStyleSheet()
styles.add(
    ParagraphStyle(
        name="CN",
        fontName=FONT,
        fontSize=9.5,
        leading=14,
        textColor=COLORS["ink"],
        alignment=TA_LEFT,
        spaceAfter=4,
    )
)
styles.add(
    ParagraphStyle(
        name="SmallCN",
        fontName=FONT,
        fontSize=8.2,
        leading=12,
        textColor=COLORS["muted"],
        alignment=TA_LEFT,
    )
)
styles.add(
    ParagraphStyle(
        name="CardTitle",
        fontName=FONT,
        fontSize=12.5,
        leading=16,
        textColor=COLORS["navy"],
        alignment=TA_LEFT,
    )
)
styles.add(
    ParagraphStyle(
        name="Hero",
        fontName=FONT,
        fontSize=23,
        leading=29,
        textColor=colors.white,
        alignment=TA_LEFT,
    )
)
styles.add(
    ParagraphStyle(
        name="HeroSub",
        fontName=FONT,
        fontSize=10.5,
        leading=15,
        textColor=colors.HexColor("#DDE8F8"),
        alignment=TA_LEFT,
    )
)
styles.add(
    ParagraphStyle(
        name="DisplaySub",
        fontName=FONT,
        fontSize=14,
        leading=20,
        textColor=colors.HexColor("#DDE8F8"),
        alignment=TA_LEFT,
    )
)
styles.add(
    ParagraphStyle(
        name="CenterSmall",
        fontName=FONT,
        fontSize=8.5,
        leading=12,
        textColor=COLORS["muted"],
        alignment=TA_CENTER,
    )
)


def para(c, text, x, y, w, style_name="CN"):
    p = Paragraph(text, styles[style_name])
    _w, h = p.wrap(w, 1000)
    p.drawOn(c, x, y - h)
    return h


def pill(c, x, y, text, fill, stroke=None, text_color=colors.white):
    c.setFont(FONT, 8.2)
    tw = pdfmetrics.stringWidth(text, FONT, 8.2)
    w = tw + 9 * mm
    h = 6.2 * mm
    c.setFillColor(fill)
    c.setStrokeColor(stroke or fill)
    c.roundRect(x, y - h, w, h, 3 * mm, stroke=1, fill=1)
    c.setFillColor(text_color)
    c.drawString(x + 4.5 * mm, y - 4.3 * mm, text)
    return w


def card(c, x, y, w, h, title, body, accent=COLORS["blue"]):
    c.setFillColor(colors.white)
    c.setStrokeColor(COLORS["line"])
    c.roundRect(x, y - h, w, h, 3 * mm, stroke=1, fill=1)
    c.setFillColor(accent)
    c.roundRect(x, y - h, 2.2 * mm, h, 1 * mm, stroke=0, fill=1)
    para(c, title, x + 7 * mm, y - 5.5 * mm, w - 12 * mm, "CardTitle")
    para(c, body, x + 7 * mm, y - 18 * mm, w - 12 * mm, "SmallCN")


def page_header(c, title, page_no):
    w, h = A4
    c.setFillColor(colors.white)
    c.rect(0, 0, w, h, fill=1, stroke=0)
    c.setFillColor(COLORS["navy"])
    c.rect(0, h - 17 * mm, w, 17 * mm, fill=1, stroke=0)
    c.setFillColor(colors.white)
    c.setFont(FONT, 12)
    c.drawString(18 * mm, h - 10.7 * mm, title)
    c.setFillColor(colors.HexColor("#B9C9DE"))
    c.setFont(FONT, 8)
    c.drawRightString(w - 18 * mm, h - 10.5 * mm, f"MoonSuite Exhibition Kit / {page_no}")


def footer(c):
    w, _h = A4
    c.setStrokeColor(COLORS["line"])
    c.line(18 * mm, 14 * mm, w - 18 * mm, 14 * mm)
    c.setFillColor(COLORS["muted"])
    c.setFont(FONT, 7.8)
    c.drawString(18 * mm, 8.8 * mm, "向量贴贴 Vectie / MoonSuite - Agentic operating system for robotics and lunar operations")


def draw_moon_network(c, cx, cy, r, scale=1.0):
    c.setFillColor(COLORS["moon"])
    c.setStrokeColor(colors.HexColor("#AAB5C5"))
    c.circle(cx, cy, r, fill=1, stroke=1)
    c.setStrokeColor(colors.HexColor("#BFC8D6"))
    for angle, rr in [(25, 0.55), (88, 0.32), (145, 0.44), (220, 0.36), (310, 0.5)]:
        ax = cx + math.cos(math.radians(angle)) * r * 0.48
        ay = cy + math.sin(math.radians(angle)) * r * 0.48
        c.circle(ax, ay, r * rr * 0.18, fill=0, stroke=1)
    nodes = [
        ("MoonBook", cx - r * 1.22, cy + r * 0.72, COLORS["green"]),
        ("MoonClaw", cx - r * 1.42, cy - r * 0.08, COLORS["blue"]),
        ("MoonTown", cx - r * 0.78, cy - r * 0.9, COLORS["amber"]),
        ("MoonRobo", cx + r * 0.78, cy - r * 0.9, COLORS["red"]),
        ("Moondesk", cx + r * 1.42, cy - r * 0.08, COLORS["cyan"]),
        ("MoonMoon", cx + r * 1.15, cy + r * 0.74, COLORS["navy"]),
    ]
    c.setLineWidth(1)
    for name, x, y, color in nodes:
        c.setStrokeColor(colors.HexColor("#CAD5E3"))
        c.line(cx, cy, x, y)
    for name, x, y, color in nodes:
        c.setFillColor(color)
        c.circle(x, y, 9 * mm * scale, fill=1, stroke=0)
        c.setFillColor(colors.white)
        c.setFont(FONT, 6.6 * scale)
        c.drawCentredString(x, y - 2.2 * mm * scale, name)


def draw_cover(c):
    w, h = A4
    c.setFillColor(COLORS["space"])
    c.rect(0, 0, w, h, fill=1, stroke=0)
    c.setFillColor(colors.HexColor("#0D213B"))
    c.circle(w * 0.96, h * 0.9, 80 * mm, fill=1, stroke=0)
    draw_moon_network(c, w * 0.7, h * 0.5, 30 * mm, 0.92)

    x = 20 * mm
    y = h - 34 * mm
    pill(c, x, y, "中国展会资料包", COLORS["blue"])
    para(
        c,
        "MoonSuite<br/>月栖智能体系统",
        x,
        y - 18 * mm,
        96 * mm,
        "Hero",
    )
    para(
        c,
        "从数字世界到物理机器人，再到月球作业现场。MoonSuite 用 MoonBit 技术栈构建可审计的智能体操作系统，让人类在地球上规划、监督、验证机器人在月球上的探索、建设与采矿任务。",
        x,
        y - 78 * mm,
        78 * mm,
        "HeroSub",
    )
    c.setStrokeColor(colors.HexColor("#37506F"))
    c.line(x, 76 * mm, w - 22 * mm, 76 * mm)
    highlights = [
        ("技术核心", "MoonBit + Rabbita + Lepusa + agent runtime"),
        ("首批客户", "机器人团队、科研院所、空间教育与工业自动化实验室"),
        ("业务目标", "先做可交付的机器人任务操作台，再扩展到月球数字孪生"),
    ]
    yy = 63 * mm
    for label, text in highlights:
        c.setFillColor(colors.white)
        c.setFont(FONT, 9.5)
        c.drawString(x, yy, label)
        c.setFillColor(colors.HexColor("#BFD0E6"))
        c.setFont(FONT, 8.6)
        c.drawString(x + 25 * mm, yy, text)
        yy -= 11 * mm
    c.setFillColor(colors.HexColor("#7891B1"))
    c.setFont(FONT, 8)
    c.drawString(x, 24 * mm, "项目名称 / 公司介绍 / 商业计划书 / 项目介绍 / 项目展示图片 / 重点介绍")
    c.showPage()


def draw_info_page(c):
    page_header(c, "展会填写信息", "01")
    w, h = A4
    x = 18 * mm
    y = h - 27 * mm
    card(
        c,
        x,
        y,
        w - 36 * mm,
        32 * mm,
        "项目名称",
        "<b>MoonSuite（月栖智能体系统）</b><br/>一句话介绍：面向未来月球机器人作业的智能体操作系统，把研究、规划、仿真、执行、安全审计与知识沉淀连接成一个闭环。",
        COLORS["blue"],
    )
    y -= 40 * mm
    card(
        c,
        x,
        y,
        w - 36 * mm,
        38 * mm,
        "公司介绍",
        "向量贴贴 Vectie 正在建设 MoonSuite（月栖智能体系统）：一套面向机器人、科研和未来月球任务的智能体操作系统。我们以 MoonBit 为核心工程语言，围绕 MoonBook、MoonClaw、MoonTown、Moondesk、MoonRobo、MoonMoon 构建从数字知识工作到物理机器人执行的产品矩阵。公司的判断很简单：下一代 AI 价值不在“多回答几句话”，而在让复杂任务可计划、可验证、可复盘，并能安全地进入真实世界。",
        COLORS["green"],
    )
    y -= 46 * mm
    card(
        c,
        x,
        y,
        w - 36 * mm,
        50 * mm,
        "项目介绍",
        "MoonSuite 把“目标 - 计划 - 工具 - 数据 - 机器人 - 证据 - 复盘”放在同一个闭环里。短期产品是本地优先的智能体工作台和机器人任务网关，帮助团队把 AI 执行过程、数据来源、评审结论和机器人安全门控沉淀下来；中期进入科研教育、工业自动化与机器人集成；长期面向月球探索、建设、采矿和巡检。MoonMoon 负责月球硬世界模型，MoonRobo 负责物理执行边界，MoonTown 负责编排，MoonClaw 负责执行，MoonBook 负责证据与知识，Moondesk 负责本地操作入口。",
        COLORS["cyan"],
    )
    y -= 59 * mm
    c.setFillColor(COLORS["soft"])
    c.setStrokeColor(COLORS["line"])
    c.roundRect(x, y - 69 * mm, w - 36 * mm, 69 * mm, 3 * mm, stroke=1, fill=1)
    para(c, "商业计划书", x + 7 * mm, y - 7 * mm, w - 50 * mm, "CardTitle")
    business = [
        ("切入场景", "机器人实验室和科研团队需要把任务计划、数据来源、模型结果、安全门控和复盘报告连起来，这是 MoonSuite 的第一个可交付场景。"),
        ("产品包装", "Moondesk 本地操作台 + MoonBook 证据库 + MoonClaw 任务执行器 + MoonRobo 安全前置条件；MoonMoon 作为月球/极端环境样板模型。"),
        ("收入结构", "早期以项目制 PoC、私有化部署和展教套件收回现金流；成熟后进入软件授权、模型数据包、机器人网关和长期运维订阅。"),
        ("12个月目标", "完成 1 个可演示的机器人任务闭环、1 个 MoonMoon 月球证据工作区、2-3 个合作试点，并沉淀可复用协议、输出模板和安全门控。"),
    ]
    yy = y - 24 * mm
    for k, v in business:
        c.setFillColor(COLORS["navy"])
        c.setFont(FONT, 9.2)
        c.drawString(x + 8 * mm, yy, k)
        para(c, v, x + 30 * mm, yy + 3 * mm, w - 74 * mm, "SmallCN")
        yy -= 13 * mm
    footer(c)
    c.showPage()


def draw_spotlights_page(c):
    page_header(c, "商业假设与机会", "02")
    w, h = A4
    x = 18 * mm
    y = h - 31 * mm
    para(
        c,
        "MoonSuite 的商业假设：AI 会从“聊天工具”进入“任务基础设施”。真正愿意付费的客户，不只需要一个回答，而需要系统把计划、工具、数据、机器人、安全、证据和交付结果连接起来。",
        x,
        y,
        w - 36 * mm,
        "CN",
    )

    y -= 30 * mm
    spotlights = [
        (
            "客户痛点明确",
            "机器人与科研项目里，数据、脚本、报告、设备状态和人为决策分散在不同地方，交付很难复盘，也很难规模化复制。",
            COLORS["blue"],
        ),
        (
            "先服务地球场景",
            "先做机器人实验、工业巡检、科研建模和展教演示，再把同一套协议推进到月球数字孪生和空间机器人任务。",
            COLORS["green"],
        ),
        (
            "可销售产品形态",
            "本地工作台、私有化知识库、任务执行器、机器人安全网关和行业数据包可以拆开卖，也可以组合成项目方案。",
            COLORS["amber"],
        ),
        (
            "不是黑箱外包",
            "每一次工具调用、数据引用、机器人指令、执行结果都留下证据，客户买到的是可审计流程，而不是不可解释的自动化。",
            COLORS["cyan"],
        ),
        (
            "长期壁垒",
            "协议、任务图谱、机器人安全数据、证据工作区和月球/极端环境模型会持续积累，形成工程资产和客户迁移成本。",
            colors.HexColor("#2F5D7C"),
        ),
        (
            "MoonBit-native 长期主义",
            "核心协议、状态、证据和工具链用 MoonBit 构建，更适合本地部署、可测试演进、长期维护和安全边界控制。",
            colors.HexColor("#7A4BD8"),
        ),
    ]
    col_w = (w - 42 * mm) / 2
    for i, (title, body, color) in enumerate(spotlights):
        cx = x + (i % 2) * (col_w + 6 * mm)
        cy = y - (i // 2) * 46 * mm
        card(c, cx, cy, col_w, 39 * mm, title, body, color)

    bottom = 56 * mm
    c.setFillColor(COLORS["space"])
    c.roundRect(x, bottom, w - 36 * mm, 33 * mm, 4 * mm, stroke=0, fill=1)
    c.setFillColor(colors.white)
    c.setFont(FONT, 12.5)
    c.drawString(x + 8 * mm, bottom + 20 * mm, "一句投资人能记住的话")
    c.setFillColor(colors.HexColor("#DDE8F8"))
    c.setFont(FONT, 9.5)
    c.drawString(
        x + 8 * mm,
        bottom + 10 * mm,
        "MoonSuite 把智能体从“会回答”推进到“能交付、能审计、能接机器人”。",
    )
    footer(c)
    c.showPage()


def draw_stack_page(c):
    page_header(c, "技术栈与系统闭环", "03")
    w, h = A4
    x = 18 * mm
    top = h - 32 * mm
    para(
        c,
        "MoonSuite 的技术栈可以用一句话理解：<b>MoonBit 做可信核心，Rabbita 做交互界面，Lepusa 做本地桌面外壳，MoonBook/MoonClaw/MoonTown/MoonRobo/MoonMoon 组成从知识到行动的闭环。</b>",
        x,
        top,
        w - 36 * mm,
        "CN",
    )
    cards = [
        ("MoonBit", "核心工程语言。负责类型化协议、任务模型、证据结构、命令行、服务端与可测试业务逻辑。", COLORS["blue"]),
        ("Rabbita", "浏览器 UI 框架。负责操作台、地图视图、任务面板、机器人状态、月球地形图层和投资展示界面。", COLORS["cyan"]),
        ("Lepusa", "本地桌面宿主。把 MoonBit 服务和 Rabbita UI 打包成本地应用，适合企业内网、实验室和展会演示。", COLORS["green"]),
        ("MoonBook", "可执行知识库。保存数据、报告、模型来源、评审队列、研究记录和项目复盘。", COLORS["amber"]),
        ("MoonClaw", "智能体运行时。把目标拆解成有边界的任务，运行工具，生成证据，返回可审查结果。", COLORS["red"]),
        ("MoonTown", "长期编排层。管理 standing goals、调度、路由、健康状态、多个 MoonBook 和多个 MoonClaw worker。", COLORS["navy"]),
        ("MoonRobo", "物理机器人边界。处理机器人身份、遥测、安全门控、指令意图、回放、执行证明和紧急停止。", colors.HexColor("#7A4BD8")),
        ("MoonMoon", "月球世界模型。处理月球地形、光照、资源、风险、不确定性、路线和建造/采矿约束。", colors.HexColor("#2F5D7C")),
    ]
    col_w = (w - 42 * mm) / 2
    y = top - 30 * mm
    for i, (title, body, color) in enumerate(cards):
        cx = x + (i % 2) * (col_w + 6 * mm)
        cy = y - (i // 2) * 38 * mm
        card(c, cx, cy, col_w, 32 * mm, title, body, color)

    yy = 64 * mm
    c.setFillColor(COLORS["navy"])
    c.setFont(FONT, 13)
    c.drawString(x, yy, "从一个想法到一次可靠行动")
    steps = [
        "1. 人类提出目标：研究、巡检、建造、采矿或演示。",
        "2. MoonTown 编排长期任务，MoonClaw 执行有边界的分析与工具调用。",
        "3. MoonBook 保存数据、证据、报告和评审结论。",
        "4. MoonMoon 提供月球地形与任务约束，MoonRobo 验证机器人执行边界。",
        "5. Rabbita/Lepusa 给操作员一个清晰、可解释、可展示的控制界面。",
    ]
    yy -= 9 * mm
    for s in steps:
        para(c, s, x, yy, w - 36 * mm, "SmallCN")
        yy -= 8 * mm
    footer(c)
    c.showPage()


def draw_focus_page(c):
    page_header(c, "重点介绍", "04")
    w, h = A4
    x = 18 * mm
    y = h - 32 * mm
    left_w = 78 * mm
    right_x = x + left_w + 10 * mm
    c.setFillColor(COLORS["soft"])
    c.setStrokeColor(COLORS["line"])
    c.roundRect(x, y - 126 * mm, left_w, 126 * mm, 3 * mm, stroke=1, fill=1)
    draw_moon_network(c, x + left_w / 2, y - 48 * mm, 24 * mm, 0.75)
    para(c, "展示图片说明", x + 8 * mm, y - 88 * mm, left_w - 16 * mm, "CardTitle")
    para(
        c,
        "展板主视觉建议使用本 PDF 第 6 页。它把地球操作员、智能体套件、月球地形模型和月面机器人放在同一个画面里，适合现场讲解。",
        x + 8 * mm,
        y - 103 * mm,
        left_w - 16 * mm,
        "SmallCN",
    )

    c.setFillColor(COLORS["navy"])
    c.setFont(FONT, 14)
    c.drawString(right_x, y, "商业计划主线")
    talking = [
        ("定位", "MoonSuite 是面向机器人与硬科技团队的智能体任务操作系统。"),
        ("MVP", "用 Moondesk + MoonBook + MoonClaw 打通本地任务、证据、报告和可复现输出。"),
        ("试点", "优先找机器人实验室、科研教育展馆、工业巡检团队做 2-3 个付费或联合试点。"),
        ("扩展", "把 MoonRobo 接入真实设备，把 MoonMoon 做成月球/极端环境建模样板。"),
        ("融资用途", "产品化本地工作台、完善任务协议、建设示范数据集、推进机器人集成合作。"),
    ]
    yy = y - 12 * mm
    for title, body in talking:
        c.setFillColor(COLORS["blue"])
        c.circle(right_x + 2 * mm, yy - 2 * mm, 1.8 * mm, fill=1, stroke=0)
        c.setFillColor(COLORS["navy"])
        c.setFont(FONT, 10)
        c.drawString(right_x + 7 * mm, yy - 5 * mm, title)
        para(c, body, right_x + 36 * mm, yy + 1 * mm, w - right_x - 54 * mm, "SmallCN")
        yy -= 20 * mm

    y2 = 82 * mm
    c.setFillColor(COLORS["navy"])
    c.setFont(FONT, 14)
    c.drawString(x, y2, "投资人容易听懂的差异点")
    row_y = y2 - 12 * mm
    diffs = [
        ("先小后大", "先做本地工作台和机器人任务闭环，再做月球模型，不把长期愿景当作短期收入。"),
        ("可交付资产", "每个项目都会沉淀任务协议、证据包、模型数据和复盘模板，可复制到下一位客户。"),
        ("安全优先", "所有物理动作都经过证据、评审、回放和安全门控，适合机器人与硬科技场景。"),
    ]
    for i, (title, body) in enumerate(diffs):
        card(c, x + i * ((w - 42 * mm) / 3 + 3 * mm), row_y, (w - 48 * mm) / 3, 39 * mm, title, body, [COLORS["green"], COLORS["amber"], COLORS["red"]][i])
    footer(c)
    c.showPage()


def draw_display_page(c):
    w = 20 * cm
    h = 30 * cm
    c.setPageSize((w, h))
    if GENERATED_VISUAL.exists():
        c.drawImage(ImageReader(str(GENERATED_VISUAL)), 0, 0, width=w, height=h)
    else:
        c.setFillColor(COLORS["space"])
        c.rect(0, 0, w, h, fill=1, stroke=0)

    c.setFillColor(colors.black)
    c.setFillAlpha(0.34)
    c.rect(0, 0, w, h, fill=1, stroke=0)
    c.setFillAlpha(1)

    c.setFillColor(colors.white)
    c.setFont(FONT, 34)
    c.drawString(15 * mm, h - 35 * mm, "MoonSuite")
    c.setFont(FONT, 20)
    c.setFillColor(colors.HexColor("#DDE8F8"))
    c.drawString(15 * mm, h - 53 * mm, "月栖智能体系统")
    para(
        c,
        "让智能体从数字世界走向真实世界，让地球上的人类安全地规划、监督、验证月球上的机器人工作。",
        15 * mm,
        h - 72 * mm,
        112 * mm,
        "DisplaySub",
    )

    panel_x, panel_y = 16 * mm, 97 * mm
    c.setFillColor(COLORS["space"])
    c.setFillAlpha(0.82)
    c.roundRect(panel_x, panel_y, 88 * mm, 94 * mm, 4 * mm, fill=1, stroke=0)
    c.setFillAlpha(1)
    c.setFillColor(colors.white)
    c.setFont(FONT, 16)
    c.drawString(panel_x + 7 * mm, panel_y + 76 * mm, "核心能力")
    capabilities = [
        ("MoonMoon", "月球地形、光照、资源、风险建模"),
        ("MoonRobo", "机器人数字孪生、安全门控、执行证据"),
        ("MoonTown", "长期目标、调度、任务编排"),
        ("MoonClaw", "智能体运行、工具调用、报告生成"),
        ("MoonBook", "知识库、数据、评审、复盘"),
    ]
    yy = panel_y + 62 * mm
    for title, body in capabilities:
        c.setFillColor(COLORS["blue"])
        c.circle(panel_x + 8 * mm, yy + 1.5 * mm, 1.4 * mm, fill=1, stroke=0)
        c.setFillColor(colors.white)
        c.setFont(FONT, 11)
        c.drawString(panel_x + 12 * mm, yy, title)
        c.setFillColor(colors.HexColor("#C7D6EA"))
        c.setFont(FONT, 9.2)
        c.drawString(panel_x + 12 * mm, yy - 6 * mm, body)
        yy -= 13.6 * mm

    bottom_y = 22 * mm
    c.setFillColor(COLORS["space"])
    c.setFillAlpha(0.84)
    c.roundRect(15 * mm, bottom_y, w - 30 * mm, 34 * mm, 4 * mm, fill=1, stroke=0)
    c.setFillAlpha(1)
    c.setFillColor(colors.white)
    c.setFont(FONT, 14)
    c.drawString(22 * mm, bottom_y + 21 * mm, "向量贴贴 Vectie")
    c.setFillColor(colors.HexColor("#C7D6EA"))
    c.setFont(FONT, 10.4)
    c.drawString(22 * mm, bottom_y + 10 * mm, "郭嘉安 / MoonSuite 发起人 / WeChat: vectie")
    c.showPage()
    c.setPageSize(A4)


def build():
    OUT.parent.mkdir(parents=True, exist_ok=True)
    c = canvas.Canvas(str(OUT), pagesize=A4, invariant=1)
    c.setTitle("MoonSuite Exhibition Profile")
    c.setAuthor("向量贴贴 Vectie / 郭嘉安")
    draw_cover(c)
    draw_info_page(c)
    draw_spotlights_page(c)
    draw_stack_page(c)
    draw_focus_page(c)
    draw_display_page(c)
    c.save()
    print(OUT)


if __name__ == "__main__":
    build()
