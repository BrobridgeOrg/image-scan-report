# SUSE Security — Image Scan Report

讀取 NeuVector 的 `scan_result.json`，產生含封面、Image 資訊、CVE 摘要與詳細說明的 PDF 報告。

## 目錄結構

```
report/
├── main.py                   # 主程式
├── requirements.txt          # Python 相依套件
├── Dockerfile
├── templates/
│   └── report.md.j2          # Jinja2 Markdown template
└── static/
    └── print.css             # PDF 樣式
```

## 相依套件

```bash
pip install -r requirements.txt
```

| 套件 | 用途 |
|---|---|
| `jinja2` | Markdown template 渲染 |
| `markdown` | Markdown → HTML |
| `weasyprint` | HTML → PDF |

## 使用方式

**本地執行：**

```bash
python main.py -i scan_result.json -o report.pdf
```

**容器執行（掛載當前目錄至 `/mnt`）：**

```bash
podman run --rm -v $(pwd):/mnt suse-security-report:0.1.0
```

不帶參數時使用預設路徑（符合 Linux FHS `/mnt` 慣例）：

| 參數 | 預設值 | 說明 |
|---|---|---|
| `-i`, `--input` | `/mnt/scan_result.json` | 輸入檔路徑 |
| `-o`, `--output` | `/mnt/report.pdf` | 輸出檔路徑 |

## 容器建置與交付

```bash
# 建置（從 pipeline/ 根目錄執行）
podman build -t suse-security-report:0.1.0 report/

# Air-gap 打包
podman save suse-security-report:0.1.0 -o suse-security-report.tar

# 目標機器載入
podman load -i suse-security-report.tar
```

Base image 為 `python:3.14-slim`（Debian trixie）。容器內路徑遵循 Linux FHS：

| 路徑 | 用途 |
|---|---|
| `/opt/suse-security-report` | 應用程式本體 |
| `/mnt` | 執行時的輸入／輸出掛載點 |

## Template 說明

- **`templates/report.md.j2`**：Jinja2 Markdown template，渲染後經 `markdown` 套件轉為 HTML，再由 weasyprint 輸出 PDF。
- **`static/print.css`**：列印導向樣式，`text-align: left` 避免 justify 造成技術字串排版異常。

### 可用變數

| 變數 | 內容 |
|---|---|
| `registry`, `repository`, `tag`, `image_id` | Image 基本資訊 |
| `base_os`, `digest`, `size_mb` | Image 詳細資訊 |
| `scan_date` | 掃描日期（`YYYY-MM-DD`） |
| `cvedb_version`, `cvedb_create_time` | CVE 資料庫版本 |
| `vulnerabilities` | 完整 CVE 清單（已依 High → Medium → Low 排序） |
| `cve_high`, `cve_medium`, `cve_low` | 各嚴重度的 CVE 子清單 |

### 注意事項

- Jinja2 環境啟用 `trim_blocks=True, lstrip_blocks=True`，避免 `{% for %}` 在 Markdown 表格中插入空行導致解析失敗。
- CVE description 使用 `{{ v.description | e }}` 做 HTML escape，防止描述中的 `<script>`、`<meta>` 等標籤被 Markdown parser 當作 HTML 處理。
