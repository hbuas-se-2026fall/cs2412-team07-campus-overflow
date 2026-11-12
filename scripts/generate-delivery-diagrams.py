"""Generate reviewable story-map and context-map PDF/PNG exports.

The exports are derived from repository Markdown at main@12eef8a. They are
documentation diagrams, not photographs or evidence of a live workshop.
"""

from pathlib import Path

import pypdfium2 as pdfium
from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_LEFT
from reportlab.lib.pagesizes import A3, A4, landscape
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.units import mm
from reportlab.pdfbase.cidfonts import UnicodeCIDFont
from reportlab.pdfbase.pdfmetrics import registerFont
from reportlab.pdfgen import canvas
from reportlab.platypus import Paragraph


ROOT = Path(__file__).resolve().parents[1]
STORY_DIR = ROOT / "docs" / "backlog" / "assets"
CONTEXT_DIR = ROOT / "docs" / "ddd" / "assets"
SOURCE_SHA = "12eef8a"

registerFont(UnicodeCIDFont("STSong-Light"))

TITLE = ParagraphStyle(
    "title", fontName="STSong-Light", fontSize=20, leading=24,
    textColor=colors.HexColor("#102A43"), alignment=TA_CENTER,
)
HEADING = ParagraphStyle(
    "heading", fontName="STSong-Light", fontSize=11, leading=14,
    textColor=colors.white, alignment=TA_CENTER,
)
CARD = ParagraphStyle(
    "card", fontName="STSong-Light", fontSize=9, leading=12,
    textColor=colors.HexColor("#243B53"), alignment=TA_LEFT,
)
SMALL = ParagraphStyle(
    "small", fontName="STSong-Light", fontSize=8, leading=10,
    textColor=colors.HexColor("#52667A"), alignment=TA_LEFT,
)


def paragraph(c, text, style, x, y_top, width, height):
    p = Paragraph(text, style)
    _, used = p.wrap(width, height)
    p.drawOn(c, x, y_top - used)
    return used


def draw_story_map(path: Path):
    width, height = landscape(A3)
    c = canvas.Canvas(str(path), pagesize=(width, height), pageCompression=1)
    c.setTitle("CampusOverflow 用户故事地图 v1")
    paragraph(c, "CampusOverflow 用户故事地图 v1", TITLE, 20 * mm, height - 18 * mm, width - 40 * mm, 30 * mm)
    c.setFont("STSong-Light", 9)
    c.setFillColor(colors.HexColor("#52667A"))
    c.drawCentredString(width / 2, height - 31 * mm,
                        f"来源：docs/backlog/user-story-map.md @ {SOURCE_SHA}；文档导出，非现场白板照片")

    columns = [
        ("身份与账号", ["访客注册账号并登录", "登录用户维护个人资料", "教师审批学生选课申请"]),
        ("浏览问答", ["浏览公开问题列表", "查看问题详情与全部回答"]),
        ("发布提问", ["发布新问题", "编辑自己的问题", "为问题添加标签"]),
        ("回答问题", ["提交回答", "编辑自己的回答"]),
        ("问答互动", ["点赞或点踩", "提问者采纳回答", "按标签归类"]),
        ("声誉成长", ["行为触发声誉变化", "查看声誉分数"]),
    ]
    margin = 14 * mm
    gap = 3 * mm
    col_w = (width - 2 * margin - gap * 5) / 6
    header_top = height - 43 * mm
    header_h = 18 * mm
    card_h = 26 * mm
    for idx, (name, cards) in enumerate(columns):
        x = margin + idx * (col_w + gap)
        c.setFillColor(colors.HexColor("#1665D8"))
        c.roundRect(x, header_top - header_h, col_w, header_h, 4 * mm, fill=1, stroke=0)
        paragraph(c, name, HEADING, x + 3 * mm, header_top - 5 * mm, col_w - 6 * mm, header_h - 5 * mm)
        y = header_top - header_h - 5 * mm
        for card in cards:
            c.setFillColor(colors.HexColor("#EAF2FF"))
            c.setStrokeColor(colors.HexColor("#A9C7F5"))
            c.roundRect(x, y - card_h, col_w, card_h, 3 * mm, fill=1, stroke=1)
            paragraph(c, card, CARD, x + 4 * mm, y - 5 * mm, col_w - 8 * mm, card_h - 6 * mm)
            y -= card_h + 4 * mm

    skeleton_y = 38 * mm
    c.setFillColor(colors.HexColor("#E8F5E9"))
    c.setStrokeColor(colors.HexColor("#6FBF73"))
    c.roundRect(margin, skeleton_y, width - 2 * margin, 42 * mm, 4 * mm, fill=1, stroke=1)
    paragraph(c, "Walking Skeleton（Sprint 1）", ParagraphStyle(
        "sk", parent=HEADING, textColor=colors.HexColor("#1B5E20"), alignment=TA_LEFT,
    ), margin + 6 * mm, skeleton_y + 35 * mm, 65 * mm, 12 * mm)
    paragraph(
        c,
        "注册/登录 → 问题列表 → 问题详情 → 发布提问 → 提交回答。投票、采纳与声誉在后续 Sprint 完成。",
        CARD, margin + 6 * mm, skeleton_y + 22 * mm, width - 2 * margin - 12 * mm, 16 * mm,
    )
    c.setFont("STSong-Light", 8)
    c.setFillColor(colors.HexColor("#7B8794"))
    c.drawRightString(width - margin, 15 * mm, "生成日期：2026-11-03")
    c.showPage()
    c.save()


def arrow(c, x1, y1, x2, y2, label):
    c.setStrokeColor(colors.HexColor("#486581"))
    c.setFillColor(colors.HexColor("#486581"))
    c.setLineWidth(1.5)
    c.line(x1, y1, x2, y2)
    direction = 1 if x2 >= x1 else -1
    c.line(x2, y2, x2 - direction * 4 * mm, y2 + 2 * mm)
    c.line(x2, y2, x2 - direction * 4 * mm, y2 - 2 * mm)
    c.setFont("STSong-Light", 8)
    c.drawCentredString((x1 + x2) / 2, (y1 + y2) / 2 + 3 * mm, label)


def context_box(c, x, y, w, h, title, body, fill):
    c.setFillColor(fill)
    c.setStrokeColor(colors.HexColor("#829AB1"))
    c.roundRect(x, y, w, h, 4 * mm, fill=1, stroke=1)
    paragraph(c, title, ParagraphStyle(
        "context-title", parent=HEADING, textColor=colors.HexColor("#102A43"), fontSize=14,
    ), x + 5 * mm, y + h - 7 * mm, w - 10 * mm, 14 * mm)
    paragraph(c, body, CARD, x + 6 * mm, y + h - 25 * mm, w - 12 * mm, h - 28 * mm)


def draw_context_map(path: Path):
    width, height = landscape(A4)
    c = canvas.Canvas(str(path), pagesize=(width, height), pageCompression=1)
    c.setTitle("CampusOverflow Context Map v1")
    paragraph(c, "CampusOverflow 限界上下文映射 v1", TITLE, 20 * mm, height - 15 * mm, width - 40 * mm, 25 * mm)
    c.setFont("STSong-Light", 8)
    c.setFillColor(colors.HexColor("#52667A"))
    c.drawCentredString(width / 2, height - 27 * mm,
                        f"来源：docs/ddd/context-map.md @ {SOURCE_SHA}；文档导出，非事件风暴现场截图")

    bw, bh = 61 * mm, 37 * mm
    identity = (17 * mm, 91 * mm)
    qa = (118 * mm, 91 * mm)
    reputation = (17 * mm, 28 * mm)
    discovery = (118 * mm, 28 * mm)
    context_box(c, *identity, bw, bh, "Identity", "用户、角色、课程成员关系；向其他上下文提供只读身份信息。", colors.HexColor("#FFF3CD"))
    context_box(c, *qa, bw, bh, "Q&amp;A", "问题、回答、评论、投票与采纳；发布公共集成事件。", colors.HexColor("#DDEBFF"))
    context_box(c, *reputation, bw, bh, "Reputation", "账户、账本、悬赏、徽章与排行榜；消费 Q&amp;A 事件。", colors.HexColor("#E8F5E9"))
    context_box(c, *discovery, bw, bh, "Discovery", "搜索索引、相关问题和通知投影；消费 Q&amp;A 事件。", colors.HexColor("#F3E8FF"))

    arrow(c, identity[0] + bw, identity[1] + bh / 2, qa[0], qa[1] + bh / 2, "客户-供应商：只读身份")
    arrow(c, qa[0], qa[1] + 5 * mm, reputation[0] + bw, reputation[1] + bh - 5 * mm, "发布-订阅：声誉事件")
    arrow(c, qa[0] + bw / 2, qa[1], discovery[0] + bw / 2, discovery[1] + bh, "事件投影：索引/通知")
    c.setFont("STSong-Light", 8)
    c.setFillColor(colors.HexColor("#7B8794"))
    c.drawRightString(width - 12 * mm, 10 * mm, "生成日期：2026-11-03")
    c.showPage()
    c.save()


def render_png(pdf_path: Path, png_path: Path):
    doc = pdfium.PdfDocument(str(pdf_path))
    page = doc[0]
    image = page.render(scale=2.0).to_pil().convert("RGB")
    image.save(png_path, format="PNG", optimize=True)


def main():
    STORY_DIR.mkdir(parents=True, exist_ok=True)
    CONTEXT_DIR.mkdir(parents=True, exist_ok=True)
    story_pdf = STORY_DIR / "user-story-map-v1.pdf"
    context_pdf = CONTEXT_DIR / "context-map-v1.pdf"
    draw_story_map(story_pdf)
    draw_context_map(context_pdf)
    render_png(story_pdf, STORY_DIR / "user-story-map-v1.png")
    render_png(context_pdf, CONTEXT_DIR / "context-map-v1.png")
    print(story_pdf)
    print(context_pdf)


if __name__ == "__main__":
    main()
