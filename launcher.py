"""
AG Robot AutoFrame - Launcher Server
A lightweight local server that provides a dashboard UI for the framework.
"""
import http.server
import json
import os
import subprocess
import sys
import threading
import time
import webbrowser
from datetime import datetime
from pathlib import Path
from urllib.parse import parse_qs

PROJECT_ROOT = Path(__file__).parent.resolve()
REPORTS_DIR = PROJECT_ROOT / "Reports"
RECORDED_DATA = PROJECT_ROOT / "Recorded Data"
PAGE_OBJECTS_DIR = RECORDED_DATA / "Page Objects"

PORT = 8090

# Track running test process
test_process = None
test_output_lines = []
test_running = False


class ThreadedHTTPServer(http.server.HTTPServer):
    """Handle each request in a separate thread to prevent blocking."""
    allow_reuse_address = True
    allow_reuse_port = True

    def process_request(self, request, client_address):
        t = threading.Thread(target=self._handle, args=(request, client_address))
        t.daemon = True
        t.start()

    def _handle(self, request, client_address):
        try:
            self.finish_request(request, client_address)
        except Exception:
            self.handle_error(request, client_address)
        finally:
            self.shutdown_request(request)


class LauncherHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(PROJECT_ROOT), **kwargs)

    def do_GET(self):
        if self.path == "/":
            self.path = "/launcher.html"
            return super().do_GET()

        if self.path == "/api/reports":
            self._send_json(self._get_reports())
            return

        if self.path == "/api/status":
            self._send_json({
                "test_running": test_running,
                "output_lines": test_output_lines[-50:]
            })
            return

        if self.path == "/api/configs":
            self._send_json(self._get_configs())
            return

        return super().do_GET()

    def do_POST(self):
        global test_process, test_output_lines, test_running

        if self.path == "/api/run-tests":
            if test_running:
                self._send_json({"error": "Tests already running"}, 409)
                return
            test_output_lines = []
            test_running = True
            t = threading.Thread(target=self._run_tests, daemon=True)
            t.start()
            self._send_json({"status": "started"})
            return

        if self.path == "/api/stop-tests":
            if test_process and test_running:
                test_process.terminate()
                test_running = False
                test_output_lines.append("[Tests stopped by user]")
                self._send_json({"status": "stopped"})
            else:
                self._send_json({"error": "No tests running"}, 400)
            return

        if self.path == "/api/open-report":
            content_len = int(self.headers.get('Content-Length', 0))
            body = json.loads(self.rfile.read(content_len)) if content_len else {}
            folder = body.get("folder", "")
            report_path = REPORTS_DIR / folder / "ag_autoframe_report.html"
            if report_path.exists():
                webbrowser.open(str(report_path))
                self._send_json({"status": "opened"})
            else:
                self._send_json({"error": "Report not found"}, 404)
            return

        if self.path == "/api/open-folder":
            content_len = int(self.headers.get('Content-Length', 0))
            body = json.loads(self.rfile.read(content_len)) if content_len else {}
            folder = body.get("path", str(PROJECT_ROOT))
            target = PROJECT_ROOT / folder if folder != str(PROJECT_ROOT) else PROJECT_ROOT
            if target.exists():
                os.startfile(str(target))
                self._send_json({"status": "opened"})
            else:
                self._send_json({"error": "Folder not found"}, 404)
            return

        self._send_json({"error": "Not found"}, 404)

    def _run_tests(self):
        global test_process, test_running, test_output_lines
        try:
            # Build report folder name
            now = datetime.now()
            folder_name = now.strftime("Report %d%m%Y  %H%M%S")
            report_dir = REPORTS_DIR / folder_name
            report_dir.mkdir(parents=True, exist_ok=True)

            test_output_lines.append(f"[{now.strftime('%H:%M:%S')}] Starting test execution...")
            test_output_lines.append(f"Report folder: {folder_name}")

            cmd = [
                sys.executable, "-m", "robot",
                "--outputdir", str(report_dir),
                "--variable", f'REPORT_DIR:{report_dir}',
                str(PROJECT_ROOT / "RobotFramework" / "tests" / "test_e2e.robot")
            ]

            test_process = subprocess.Popen(
                cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                text=True, cwd=str(PROJECT_ROOT), bufsize=1
            )

            for line in iter(test_process.stdout.readline, ''):
                test_output_lines.append(line.rstrip())

            test_process.wait()
            exit_code = test_process.returncode
            test_output_lines.append("")
            if exit_code == 0:
                test_output_lines.append("=== ALL TESTS PASSED ===")
            else:
                test_output_lines.append(f"=== TESTS COMPLETED (exit code: {exit_code}) ===")

            test_output_lines.append(f"Report: {report_dir / 'ag_autoframe_report.html'}")

        except Exception as e:
            test_output_lines.append(f"ERROR: {e}")
        finally:
            test_running = False
            test_process = None

    def _get_reports(self):
        reports = []
        if REPORTS_DIR.exists():
            for folder in sorted(REPORTS_DIR.iterdir(), reverse=True):
                if folder.is_dir():
                    report_file = folder / "ag_autoframe_report.html"
                    robot_output = folder / "output.xml"
                    # Parse basic info from output.xml if available
                    status = "unknown"
                    if robot_output.exists():
                        try:
                            content = robot_output.read_text(encoding="utf-8", errors="ignore")[:2000]
                            if 'status="PASS"' in content:
                                status = "PASS"
                            elif 'status="FAIL"' in content:
                                status = "FAIL"
                        except:
                            pass
                    reports.append({
                        "folder": folder.name,
                        "has_report": report_file.exists(),
                        "status": status,
                        "timestamp": folder.name.replace("Report ", "")
                    })
        return reports

    def _get_configs(self):
        configs = []
        # Main output.json
        main_config = RECORDED_DATA / "output.json"
        if main_config.exists():
            configs.append({
                "name": "output.json",
                "path": "Recorded Data/output.json",
                "type": "main"
            })
        # Page objects
        if PAGE_OBJECTS_DIR.exists():
            for f in sorted(PAGE_OBJECTS_DIR.iterdir()):
                if f.suffix == ".json":
                    configs.append({
                        "name": f.name,
                        "path": f"Recorded Data/Page Objects/{f.name}",
                        "type": "pageobject"
                    })
        return configs

    def _send_json(self, data, code=200):
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        self.wfile.write(json.dumps(data).encode())

    def log_message(self, format, *args):
        pass  # Suppress console logging


def main():
    no_browser = "--no-browser" in sys.argv
    server = ThreadedHTTPServer(("0.0.0.0", PORT), LauncherHandler)
    print(f"AG Robot AutoFrame Launcher running at http://localhost:{PORT}")
    print("Press Ctrl+C to stop.")
    # Start server in a thread first, then open browser after it's ready
    if not no_browser:
        def open_browser():
            time.sleep(1.5)
            webbrowser.open(f"http://localhost:{PORT}")
        threading.Thread(target=open_browser, daemon=True).start()
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nShutting down.")
        server.server_close()


if __name__ == "__main__":
    main()
