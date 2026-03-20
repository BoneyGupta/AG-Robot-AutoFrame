import os
import json
import base64
from datetime import datetime
from robot.api import logger


class ReportGenerator:
    """Generates a custom HTML report with split-panel layout:
    step cards on the left, screenshot viewer on the right."""

    ROBOT_LIBRARY_SCOPE = 'SUITE'

    def generate_report(self, report_dir, config_path, results_list, executed, failed):
        with open(config_path, 'r', encoding='utf-8') as f:
            config = json.load(f)

        step_lookup = {}
        for step in config.get('steps', []):
            step_lookup[str(step['stepNumber'])] = step

        timestamp = datetime.now().strftime('%d-%m-%Y %H:%M:%S')
        passed = int(executed) - int(failed)
        total = int(executed)

        html = self._build_html(config, step_lookup, results_list, timestamp, total, passed, int(failed))

        report_path = os.path.join(report_dir, 'ag_autoframe_report.html')
        with open(report_path, 'w', encoding='utf-8') as f:
            f.write(html)

        logger.info(f"Custom report generated at: {report_path}")
        return report_path

    def _encode_image(self, path):
        if not path or not os.path.exists(path):
            return None
        try:
            with open(path, 'rb') as f:
                return base64.b64encode(f.read()).decode('utf-8')
        except Exception:
            return None

    def _build_html(self, config, step_lookup, results_list, timestamp, total, passed, failed):
        skipped = sum(1 for r in results_list if r.get('status') == 'SKIP')

        if failed > 0:
            overall_status = 'FAIL'
            overall_class = 'status-fail'
        else:
            overall_status = 'PASS'
            overall_class = 'status-pass'

        # Build step data as JSON for the JS to consume
        steps_json_list = []
        for idx, result in enumerate(results_list):
            step_num = str(result.get('step', ''))
            status = result.get('status', 'UNKNOWN')
            action = result.get('action', '')
            section = result.get('section', '')
            message = result.get('message', '')

            step_config = step_lookup.get(step_num, {})
            xpath = step_config.get('xpath', '')
            element_dom = step_config.get('elementDOM', '')
            element_tag = step_config.get('elementTagName', '')
            element_text = step_config.get('elementTextContent', '')
            input_val = step_config.get('inputValue', '')
            description = step_config.get('description', '')
            wait_list = step_config.get('wait', [])
            save_var = step_config.get('save', '')

            wait_info = ''
            for w in wait_list:
                wt = w.get('waitType', '')
                to = w.get('Timeout', 0)
                if wt:
                    wait_info += f'{wt} ({to}ms) '

            before_b64 = self._encode_image(result.get('before', ''))
            during_b64 = self._encode_image(result.get('during', ''))
            after_b64 = self._encode_image(result.get('after', ''))

            # Capture variable store snapshot
            variables = result.get('variables', {})
            # Convert RobotFramework DotDict to plain dict if needed
            if hasattr(variables, 'items'):
                variables = dict(variables)
            else:
                variables = {}

            steps_json_list.append({
                'step': step_num,
                'status': status,
                'action': action,
                'section': section,
                'message': message,
                'xpath': xpath,
                'elementDOM': element_dom,
                'elementTag': element_tag,
                'elementText': element_text,
                'inputValue': input_val,
                'description': description,
                'waitInfo': wait_info.strip(),
                'saveVar': save_var,
                'before': before_b64 or '',
                'during': during_b64 or '',
                'after': after_b64 or '',
                'variables': variables,
            })

        steps_json_str = json.dumps(steps_json_list)

        html = f'''<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>AG Robot AutoFrame Test Report</title>
    <style>
        * {{ margin: 0; padding: 0; box-sizing: border-box; }}
        body {{
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: #f0f2f5;
            color: #333;
            height: 100vh;
            overflow: hidden;
        }}

        /* ── Top bar ── */
        .top-bar {{
            background: linear-gradient(135deg, #1a1a2e 0%, #16213e 50%, #0f3460 100%);
            color: white;
            padding: 16px 24px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            flex-shrink: 0;
        }}
        .top-bar h1 {{ font-size: 22px; }}
        .top-bar .meta {{
            display: flex;
            align-items: center;
            gap: 16px;
            font-size: 13px;
        }}
        .top-bar .meta .overall-badge {{
            padding: 4px 14px;
            border-radius: 14px;
            font-weight: 700;
            font-size: 12px;
        }}
        .overall-badge.status-pass {{ background: #27ae60; color: white; }}
        .overall-badge.status-fail {{ background: #e74c3c; color: white; }}

        /* ── Config bar ── */
        .config-bar {{
            background: white;
            border-bottom: 1px solid #e0e0e0;
            flex-shrink: 0;
        }}
        .config-toggle {{
            padding: 10px 24px;
            cursor: pointer;
            font-size: 14px;
            font-weight: 600;
            color: #1a1a2e;
            display: flex;
            align-items: center;
            gap: 8px;
            user-select: none;
        }}
        .config-toggle:hover {{ background: #f8f9fa; }}
        .config-toggle .arrow {{ font-size: 10px; transition: transform 0.2s; }}
        .config-toggle .arrow.open {{ transform: rotate(90deg); }}
        .config-content {{
            display: none;
            padding: 0 24px 14px;
        }}
        .config-grid {{
            display: flex;
            gap: 12px;
            flex-wrap: wrap;
        }}
        .config-chip {{
            background: #f0f2f5;
            padding: 8px 14px;
            border-radius: 8px;
            font-size: 13px;
            border-left: 3px solid #0f3460;
        }}
        .config-chip .label {{ font-size: 11px; color: #888; text-transform: uppercase; letter-spacing: 0.4px; }}
        .config-chip .value {{ font-weight: 600; color: #1a1a2e; }}

        /* ── Summary bar ── */
        .summary-bar {{
            display: flex;
            gap: 10px;
            padding: 12px 24px;
            background: white;
            border-bottom: 1px solid #e0e0e0;
            flex-shrink: 0;
            align-items: center;
        }}
        .summary-stat {{
            text-align: center;
            padding: 6px 18px;
            border-radius: 8px;
            background: #f8f9fa;
        }}
        .summary-stat .num {{ font-size: 22px; font-weight: 700; }}
        .summary-stat .lbl {{ font-size: 10px; color: #888; text-transform: uppercase; }}
        .summary-stat.s-total .num {{ color: #0f3460; }}
        .summary-stat.s-pass .num {{ color: #27ae60; }}
        .summary-stat.s-fail .num {{ color: #e74c3c; }}
        .summary-stat.s-skip .num {{ color: #f39c12; }}
        .summary-controls {{
            margin-left: auto;
            display: flex;
            gap: 6px;
        }}
        .ctrl-btn {{
            padding: 5px 12px;
            border: 1px solid #ddd;
            border-radius: 6px;
            background: white;
            cursor: pointer;
            font-size: 12px;
            transition: all 0.15s;
        }}
        .ctrl-btn:hover {{ background: #0f3460; color: white; border-color: #0f3460; }}
        .filter-btn {{
            padding: 4px 12px;
            border: 1px solid #ddd;
            border-radius: 14px;
            background: white;
            cursor: pointer;
            font-size: 11px;
            transition: all 0.15s;
        }}
        .filter-btn:hover, .filter-btn.active {{
            background: #0f3460; color: white; border-color: #0f3460;
        }}

        /* ── Main layout: left panel + right panel ── */
        .main-layout {{
            display: flex;
            flex: 1;
            overflow: hidden;
            height: calc(100vh - var(--top-offset, 170px));
        }}

        /* ── Left panel: step list ── */
        .left-panel {{
            width: 420px;
            min-width: 340px;
            background: #f7f8fa;
            border-right: 1px solid #e0e0e0;
            display: flex;
            flex-direction: column;
            overflow: hidden;
        }}
        .step-list {{
            flex: 1;
            overflow-y: auto;
            padding: 10px;
        }}
        .section-group {{
            margin-bottom: 12px;
        }}
        .section-header {{
            display: flex;
            align-items: center;
            gap: 8px;
            padding: 8px 12px 4px;
        }}
        .section-header:first-child {{
            margin-top: 0;
        }}
        .section-label {{
            font-size: 11px;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 0.6px;
            color: #0f3460;
            flex: 1;
        }}
        .section-count {{
            font-size: 10px;
            color: #888;
            background: #e8eaf0;
            padding: 1px 8px;
            border-radius: 10px;
        }}
        .section-stats {{
            display: flex;
            gap: 4px;
        }}
        .section-stats .mini-stat {{
            font-size: 9px;
            padding: 1px 5px;
            border-radius: 8px;
            font-weight: 600;
        }}
        .mini-stat.mp {{ background: #e8f5e9; color: #27ae60; }}
        .mini-stat.mf {{ background: #fde8e8; color: #e74c3c; }}
        .mini-stat.ms {{ background: #fff3e0; color: #f39c12; }}
        .step-card {{
            background: white;
            border-radius: 8px;
            margin-bottom: 6px;
            box-shadow: 0 1px 3px rgba(0,0,0,0.06);
            overflow: hidden;
            transition: box-shadow 0.15s;
        }}
        .step-card:hover {{ box-shadow: 0 2px 8px rgba(0,0,0,0.12); }}
        .step-card.selected {{ box-shadow: 0 0 0 2px #0f3460, 0 2px 8px rgba(0,0,0,0.12); }}
        .step-header {{
            padding: 12px 14px;
            cursor: pointer;
            display: flex;
            align-items: center;
            justify-content: space-between;
        }}
        .step-header:hover {{ background: #fafbfc; }}
        .step-left {{
            display: flex;
            align-items: center;
            gap: 10px;
        }}
        .step-num {{
            font-weight: 700;
            font-size: 13px;
            color: #1a1a2e;
            min-width: 50px;
        }}
        .badge {{
            padding: 2px 8px;
            border-radius: 10px;
            font-size: 11px;
            font-weight: 600;
        }}
        .status-pass {{ background: #e8f5e9; color: #27ae60; }}
        .status-fail {{ background: #fde8e8; color: #e74c3c; }}
        .status-skip {{ background: #fff3e0; color: #f39c12; }}
        .step-action-label {{
            font-size: 12px;
            color: #555;
            font-weight: 500;
        }}
        .step-section-label {{
            font-size: 11px;
            color: #999;
        }}
        .step-toggle {{
            font-size: 10px;
            color: #bbb;
            transition: transform 0.2s;
        }}
        .step-toggle.open {{ transform: rotate(90deg); }}

        /* ── Step detail row (below header, inside left panel) ── */
        .step-detail-row {{
            display: none;
            padding: 0 14px 12px;
            border-top: 1px solid #f0f0f0;
        }}
        .detail-table {{
            width: 100%;
            font-size: 12px;
            border-collapse: collapse;
        }}
        .detail-table td {{
            padding: 4px 0;
            vertical-align: top;
        }}
        .detail-table td:first-child {{
            font-weight: 600;
            color: #666;
            width: 100px;
            white-space: nowrap;
            padding-right: 10px;
        }}
        .detail-table td:last-child {{
            color: #333;
            word-break: break-all;
        }}
        .detail-table code {{
            background: #f0f2f5;
            padding: 1px 4px;
            border-radius: 3px;
            font-size: 11px;
        }}

        /* ── Right panel: screenshot viewer ── */
        .right-panel {{
            flex: 1;
            display: flex;
            flex-direction: column;
            overflow: hidden;
            background: #ebedf0;
        }}
        .screenshot-viewer {{
            flex: 1;
            overflow-y: auto;
            padding: 20px;
            display: flex;
            flex-direction: column;
            align-items: center;
        }}
        .screenshot-placeholder {{
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            height: 100%;
            color: #aaa;
            font-size: 15px;
            gap: 10px;
        }}
        .screenshot-placeholder .icon {{ font-size: 48px; opacity: 0.3; }}

        /* ── Screenshot tabs ── */
        .ss-tabs {{
            display: flex;
            gap: 0;
            background: white;
            border-bottom: 1px solid #e0e0e0;
            flex-shrink: 0;
        }}
        .ss-tab {{
            flex: 1;
            padding: 10px;
            text-align: center;
            font-size: 13px;
            font-weight: 500;
            cursor: pointer;
            border-bottom: 3px solid transparent;
            color: #888;
            transition: all 0.15s;
            user-select: none;
        }}
        .ss-tab:hover {{ background: #f8f9fa; color: #333; }}
        .ss-tab.active {{
            color: #0f3460;
            border-bottom-color: #0f3460;
            background: white;
        }}
        .ss-tab .tab-label {{ font-size: 12px; }}
        .ss-tab .tab-sub {{ font-size: 10px; color: #bbb; }}
        .ss-tab.active .tab-sub {{ color: #0f3460; opacity: 0.6; }}

        .screenshot-img-wrap {{
            width: 100%;
            max-width: 960px;
            text-align: center;
        }}
        .screenshot-img-wrap img {{
            width: 100%;
            border: 1px solid #d0d0d0;
            border-radius: 8px;
            cursor: pointer;
            transition: box-shadow 0.2s;
        }}
        .screenshot-img-wrap img:hover {{
            box-shadow: 0 4px 20px rgba(0,0,0,0.15);
        }}
        .no-screenshot-msg {{
            padding: 60px;
            color: #bbb;
            font-size: 14px;
            text-align: center;
            background: #f8f9fa;
            border-radius: 8px;
        }}
        .ss-step-title {{
            font-size: 16px;
            font-weight: 600;
            color: #1a1a2e;
            margin-bottom: 16px;
            text-align: center;
        }}

        /* ── Lightbox ── */
        .lightbox {{
            display: none;
            position: fixed;
            top: 0; left: 0;
            width: 100%; height: 100%;
            background: rgba(0,0,0,0.88);
            z-index: 1000;
            justify-content: center;
            align-items: center;
            cursor: pointer;
        }}
        .lightbox.active {{ display: flex; }}
        .lightbox img {{
            max-width: 92%;
            max-height: 92%;
            border-radius: 6px;
        }}

        /* ── Scrollbar ── */
        .step-list::-webkit-scrollbar,
        .screenshot-viewer::-webkit-scrollbar {{
            width: 6px;
        }}
        .step-list::-webkit-scrollbar-thumb,
        .screenshot-viewer::-webkit-scrollbar-thumb {{
            background: #ccc;
            border-radius: 3px;
        }}

        /* ── Page wrapper ── */
        .page-wrap {{
            display: flex;
            flex-direction: column;
            height: 100vh;
        }}
    </style>
</head>
<body>
<div class="page-wrap">
    <!-- Top bar -->
    <div class="top-bar">
        <h1>AG Robot AutoFrame Test Report</h1>
        <div class="meta">
            <span>{timestamp}</span>
            <span class="overall-badge {overall_class}">{overall_status}</span>
        </div>
    </div>

    <!-- Config bar -->
    <div class="config-bar">
        <div class="config-toggle" onclick="toggleConfig()">
            <span class="arrow" id="config-arrow">&#9654;</span>
            Configuration
        </div>
        <div class="config-content" id="config-content">
            <div class="config-grid">
                <div class="config-chip">
                    <div class="label">Browser</div>
                    <div class="value">{config.get('browser', 'N/A')}</div>
                </div>
                <div class="config-chip">
                    <div class="label">Headed</div>
                    <div class="value">{config.get('headed', 'N/A')}</div>
                </div>
                <div class="config-chip">
                    <div class="label">Implicit Wait</div>
                    <div class="value">{config.get('implicitWait', 'N/A')}ms</div>
                </div>
                <div class="config-chip">
                    <div class="label">Start URL</div>
                    <div class="value">{config.get('startURL', 'N/A')}</div>
                </div>
                <div class="config-chip">
                    <div class="label">Total Steps</div>
                    <div class="value">{len(config.get('steps', []))}</div>
                </div>
            </div>
        </div>
    </div>

    <!-- Summary bar -->
    <div class="summary-bar">
        <div class="summary-stat s-total">
            <div class="num">{total}</div><div class="lbl">Total</div>
        </div>
        <div class="summary-stat s-pass">
            <div class="num">{passed}</div><div class="lbl">Passed</div>
        </div>
        <div class="summary-stat s-fail">
            <div class="num">{failed}</div><div class="lbl">Failed</div>
        </div>
        <div class="summary-stat s-skip">
            <div class="num">{skipped}</div><div class="lbl">Skipped</div>
        </div>
        <div class="summary-controls">
            <button class="filter-btn active" onclick="filterSteps('all',this)">All</button>
            <button class="filter-btn" onclick="filterSteps('PASS',this)">Passed</button>
            <button class="filter-btn" onclick="filterSteps('FAIL',this)">Failed</button>
            <button class="filter-btn" onclick="filterSteps('SKIP',this)">Skipped</button>
            <button class="ctrl-btn" onclick="expandAll()">Expand All</button>
            <button class="ctrl-btn" onclick="collapseAll()">Collapse All</button>
        </div>
    </div>

    <!-- Main split layout -->
    <div class="main-layout">
        <!-- Left: step cards -->
        <div class="left-panel">
            <div class="step-list" id="step-list"></div>
        </div>

        <!-- Right: screenshot viewer -->
        <div class="right-panel">
            <div class="ss-tabs" id="ss-tabs" style="display:none;">
                <div class="ss-tab active" data-phase="before" onclick="switchTab('before',this)">
                    <div class="tab-label">Before</div>
                    <div class="tab-sub">Pre-action state</div>
                </div>
                <div class="ss-tab" data-phase="during" onclick="switchTab('during',this)">
                    <div class="tab-label">During</div>
                    <div class="tab-sub">Element highlighted</div>
                </div>
                <div class="ss-tab" data-phase="after" onclick="switchTab('after',this)">
                    <div class="tab-label">After</div>
                    <div class="tab-sub">Post-action state</div>
                </div>
            </div>
            <div class="screenshot-viewer" id="screenshot-viewer">
                <div class="screenshot-placeholder">
                    <div class="icon">&#128247;</div>
                    <div>Click a step to view screenshots</div>
                </div>
            </div>
        </div>
    </div>
</div>

<!-- Lightbox -->
<div class="lightbox" id="lightbox" onclick="closeLightbox()">
    <img id="lightbox-img" src="" alt="">
</div>

<script>
var STEPS = {steps_json_str};
var selectedStep = null;
var currentPhase = 'before';

function init() {{
    var list = document.getElementById('step-list');

    // Group steps by section
    var sections = [];
    var sectionMap = {{}};
    STEPS.forEach(function(s, i) {{
        var sec = s.section || 'Uncategorized';
        if (!(sec in sectionMap)) {{
            sectionMap[sec] = {{ name: sec, steps: [] }};
            sections.push(sectionMap[sec]);
        }}
        sectionMap[sec].steps.push({{ data: s, index: i }});
    }});

    sections.forEach(function(sec) {{
        // Count pass/fail/skip per section
        var sp = 0, sf = 0, ss = 0;
        sec.steps.forEach(function(item) {{
            if (item.data.status === 'PASS') sp++;
            else if (item.data.status === 'FAIL') sf++;
            else ss++;
        }});

        // Section header
        var sectionGroup = document.createElement('div');
        sectionGroup.className = 'section-group';
        sectionGroup.setAttribute('data-section', sec.name);

        var statsHtml = '';
        if (sp > 0) statsHtml += '<span class="mini-stat mp">' + sp + ' P</span>';
        if (sf > 0) statsHtml += '<span class="mini-stat mf">' + sf + ' F</span>';
        if (ss > 0) statsHtml += '<span class="mini-stat ms">' + ss + ' S</span>';

        var header = document.createElement('div');
        header.className = 'section-header';
        header.innerHTML =
            '<span class="section-label">' + esc(sec.name) + '</span>' +
            '<div class="section-stats">' + statsHtml + '</div>' +
            '<span class="section-count">' + sec.steps.length + '</span>';
        sectionGroup.appendChild(header);

        // Step cards within section
        sec.steps.forEach(function(item) {{
            var s = item.data;
            var i = item.index;
            var statusClass = s.status === 'PASS' ? 'status-pass' : s.status === 'FAIL' ? 'status-fail' : 'status-skip';
            var statusIcon = s.status === 'PASS' ? '&#10004;' : s.status === 'FAIL' ? '&#10008;' : '&#8674;';

            var detailRows = '';
            detailRows += '<tr><td>Action</td><td>' + esc(s.action) + '</td></tr>';
            detailRows += '<tr><td>Status</td><td><span class="' + statusClass + '" style="padding:1px 6px;border-radius:8px;font-size:11px;">' + s.status + '</span></td></tr>';
            if (s.message) detailRows += '<tr><td>Message</td><td>' + esc(s.message) + '</td></tr>';
            if (s.xpath) detailRows += '<tr><td>XPath</td><td><code>' + esc(s.xpath) + '</code></td></tr>';
            if (s.elementTag) detailRows += '<tr><td>Tag</td><td>' + esc(s.elementTag) + '</td></tr>';
            if (s.elementText) detailRows += '<tr><td>Text</td><td>' + esc(s.elementText) + '</td></tr>';
            if (s.elementDOM) detailRows += '<tr><td>DOM</td><td><code>' + esc(s.elementDOM) + '</code></td></tr>';
            if (s.inputValue) detailRows += '<tr><td>Input</td><td>' + esc(s.inputValue) + '</td></tr>';
            if (s.waitInfo) detailRows += '<tr><td>Wait</td><td>' + esc(s.waitInfo) + '</td></tr>';
            if (s.saveVar) detailRows += '<tr><td>Save Var</td><td>' + esc(s.saveVar) + '</td></tr>';
            if (s.description) detailRows += '<tr><td>Description</td><td>' + esc(s.description) + '</td></tr>';

            // Variables snapshot
            if (s.variables && Object.keys(s.variables).length > 0) {{
                var varHtml = '<div style="background:#f0f2f5;border-radius:6px;padding:8px 10px;margin-top:2px">';
                Object.keys(s.variables).forEach(function(k) {{
                    varHtml += '<div style="display:flex;gap:8px;padding:2px 0;font-size:11px">' +
                        '<span style="font-weight:600;color:#0f3460;min-width:140px">bb.local.' + esc(k) + '</span>' +
                        '<span style="color:#333">' + esc(s.variables[k]) + '</span>' +
                    '</div>';
                }});
                varHtml += '</div>';
                detailRows += '<tr><td>Variables</td><td>' + varHtml + '</td></tr>';
            }}

            var card = document.createElement('div');
            card.className = 'step-card';
            card.setAttribute('data-status', s.status);
            card.setAttribute('data-index', i);
            card.innerHTML =
                '<div class="step-header" onclick="selectStep(' + i + ')">' +
                    '<div class="step-left">' +
                        '<span class="step-num">Step ' + s.step + '</span>' +
                        '<span class="badge ' + statusClass + '">' + statusIcon + ' ' + s.status + '</span>' +
                        '<span class="step-action-label">' + esc(s.action) + '</span>' +
                    '</div>' +
                    '<span class="step-toggle" id="toggle-' + i + '" onclick="event.stopPropagation();toggleDetail(' + i + ')">&#9654;</span>' +
                '</div>' +
                '<div class="step-detail-row" id="detail-' + i + '">' +
                    '<table class="detail-table">' + detailRows + '</table>' +
                '</div>';
            sectionGroup.appendChild(card);
        }});

        list.appendChild(sectionGroup);
    }});
}}

function esc(t) {{
    if (!t) return '';
    var d = document.createElement('div');
    d.textContent = t;
    return d.innerHTML;
}}

function selectStep(idx) {{
    // If clicking the already-selected step, toggle its detail closed/open
    if (selectedStep === idx) {{
        toggleDetail(idx);
        return;
    }}
    // Deselect previous
    document.querySelectorAll('.step-card.selected').forEach(function(c) {{ c.classList.remove('selected'); }});
    // Collapse previously open details
    if (selectedStep !== null) {{
        var prevRow = document.getElementById('detail-' + selectedStep);
        var prevIcon = document.getElementById('toggle-' + selectedStep);
        if (prevRow) prevRow.style.display = 'none';
        if (prevIcon) prevIcon.classList.remove('open');
    }}
    // Select new
    var card = document.querySelector('.step-card[data-index="' + idx + '"]');
    if (card) card.classList.add('selected');
    selectedStep = idx;
    currentPhase = 'before';
    // Reset tabs
    document.querySelectorAll('.ss-tab').forEach(function(t) {{ t.classList.remove('active'); }});
    document.querySelector('.ss-tab[data-phase="before"]').classList.add('active');
    document.getElementById('ss-tabs').style.display = 'flex';
    showScreenshot();
    // Open detail for newly selected step
    toggleDetail(idx, true);
}}

function toggleDetail(idx, forceOpen) {{
    var row = document.getElementById('detail-' + idx);
    var icon = document.getElementById('toggle-' + idx);
    if (forceOpen) {{
        row.style.display = 'block';
        icon.classList.add('open');
    }} else if (row.style.display === 'block') {{
        row.style.display = 'none';
        icon.classList.remove('open');
    }} else {{
        row.style.display = 'block';
        icon.classList.add('open');
    }}
}}

function switchTab(phase, tabEl) {{
    currentPhase = phase;
    document.querySelectorAll('.ss-tab').forEach(function(t) {{ t.classList.remove('active'); }});
    tabEl.classList.add('active');
    showScreenshot();
}}

function showScreenshot() {{
    var viewer = document.getElementById('screenshot-viewer');
    if (selectedStep === null) return;
    var s = STEPS[selectedStep];
    var b64 = s[currentPhase];
    var phaseLabels = {{ before: 'Before Execution', during: 'During Execution (highlighted)', after: 'After Execution' }};

    if (b64) {{
        viewer.innerHTML =
            '<div class="ss-step-title">Step ' + s.step + ' &mdash; ' + phaseLabels[currentPhase] + '</div>' +
            '<div class="screenshot-img-wrap">' +
                '<img src="data:image/png;base64,' + b64 + '" onclick="openLightbox(this.src)" alt="' + currentPhase + '">' +
            '</div>';
    }} else {{
        viewer.innerHTML =
            '<div class="ss-step-title">Step ' + s.step + ' &mdash; ' + phaseLabels[currentPhase] + '</div>' +
            '<div class="no-screenshot-msg">No screenshot available</div>';
    }}
}}

function expandAll() {{
    document.querySelectorAll('.step-detail-row').forEach(function(r) {{ r.style.display = 'block'; }});
    document.querySelectorAll('.step-toggle').forEach(function(t) {{ t.classList.add('open'); }});
}}
function collapseAll() {{
    document.querySelectorAll('.step-detail-row').forEach(function(r) {{ r.style.display = 'none'; }});
    document.querySelectorAll('.step-toggle').forEach(function(t) {{ t.classList.remove('open'); }});
}}

function filterSteps(status, btn) {{
    document.querySelectorAll('.filter-btn').forEach(function(b) {{ b.classList.remove('active'); }});
    btn.classList.add('active');
    document.querySelectorAll('.step-card').forEach(function(card) {{
        if (status === 'all') {{
            card.style.display = 'block';
        }} else {{
            card.style.display = card.getAttribute('data-status') === status ? 'block' : 'none';
        }}
    }});
    // Hide section groups where all steps are hidden
    document.querySelectorAll('.section-group').forEach(function(group) {{
        var cards = group.querySelectorAll('.step-card');
        var anyVisible = false;
        cards.forEach(function(c) {{ if (c.style.display !== 'none') anyVisible = true; }});
        group.style.display = anyVisible ? 'block' : 'none';
    }});
}}

function toggleConfig() {{
    var c = document.getElementById('config-content');
    var a = document.getElementById('config-arrow');
    if (c.style.display === 'block') {{
        c.style.display = 'none';
        a.classList.remove('open');
    }} else {{
        c.style.display = 'block';
        a.classList.add('open');
    }}
}}

function openLightbox(src) {{
    document.getElementById('lightbox-img').src = src;
    document.getElementById('lightbox').classList.add('active');
}}
function closeLightbox() {{
    document.getElementById('lightbox').classList.remove('active');
}}
document.addEventListener('keydown', function(e) {{
    if (e.key === 'Escape') closeLightbox();
}});

init();
</script>
</body>
</html>'''
        return html

    def _escape_html(self, text):
        if not text:
            return ''
        return (str(text)
                .replace('&', '&amp;')
                .replace('<', '&lt;')
                .replace('>', '&gt;')
                .replace('"', '&quot;')
                .replace("'", '&#39;'))
