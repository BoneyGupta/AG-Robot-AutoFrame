# AG Robot AutoFrame Test Automation Framework

A JSON-driven, no-code test automation framework built on Robot Framework and Selenium. Define test steps in a visual editor, execute them against any web application, and get rich HTML reports with step-by-step screenshots.

---

## Table of Contents

- [Prerequisites](#prerequisites)
- [Setup](#setup)
- [Launcher Dashboard](#launcher-dashboard)
- [Quick Start](#quick-start)
- [Project Structure](#project-structure)
- [Running Tests](#running-tests)
- [Test Editor](#test-editor)
- [JSON Configuration](#json-configuration)
- [Framework Architecture](#framework-architecture)
- [Reports](#reports)
- [Modules](#modules)

---

## Prerequisites

- **Python** 3.11+ (auto-installed by `setup.bat` if missing)
- **Chrome**, **Edge**, or **Safari** browser installed
- WebDrivers are auto-managed by Selenium Manager (Selenium 4.6+)

### Dependencies (`requirements.txt`)

```
robotframework>=7.0
robotframework-seleniumlibrary>=6.0
selenium>=4.0
lxml>=5.0
```

---

## Setup

Run the setup script to install Python and all dependencies:

```
setup.bat
```

This script will:
1. Check if Python 3.11 is installed. If not, it downloads and installs it automatically.
2. Set the system PATH environment variables for Python and pip.
3. Verify pip is available and upgrade it.
4. Install all dependencies from `requirements.txt` (Robot Framework, SeleniumLibrary, Selenium, lxml).
5. Display a summary of installed packages.

After setup completes, you are ready to run tests.

---

## Launcher Dashboard

The Launcher Dashboard is a browser-based control panel for the framework. Run `launcher.bat` to start it.

```
launcher.bat
```

This starts a local server at `http://localhost:8090` and opens the dashboard in your browser.

### Dashboard Features

- **Run Tests** -- Start test execution and watch live terminal output directly in the browser. Click the button again to stop a running test.
- **Test Editor** -- Opens the visual test configuration editor in a new tab.
- **Reports** -- Browse all past test reports. Click any report to open it.
- **Recorded Data** -- Quick access to test configs and page objects.
- **Project Folder** -- Opens the project root in your file explorer.
- **Test Configurations** -- Lists `output.json` and any page object JSON files. Click to open in the editor.

### API Endpoints (for advanced use)

| Endpoint | Method | Description |
|---|---|---|
| `/api/run-tests` | POST | Start test execution |
| `/api/stop-tests` | POST | Stop a running test |
| `/api/status` | GET | Get test status and output lines |
| `/api/reports` | GET | List all report folders |
| `/api/configs` | GET | List test configuration files |
| `/api/open-report` | POST | Open a report in the default browser |
| `/api/open-folder` | POST | Open a folder in the file explorer |

---

## Quick Start

```
1. Run setup.bat              -- Installs Python + dependencies
2. Run launcher.bat           -- Opens the dashboard in your browser
3. Click "Run Tests"          -- Execute tests and see live output
4. Click a report             -- View results with step-by-step screenshots
```

Or without the dashboard:

```
1. Run setup.bat              -- Installs Python + dependencies
2. Open TestEditor/editor.html -- Create or edit test configs
3. Run test_e2e.bat           -- Execute tests and generate reports
4. Open Reports/<latest>/ag_autoframe_report.html -- View results
```

---

## Project Structure

```
AG Robot AutoFrame Project/
|
|-- launcher.bat                     # Starts the dashboard server
|-- launcher.py                      # Dashboard backend (Python HTTP server)
|-- launcher.html                    # Dashboard frontend UI
|
|-- TestEditor/
|   +-- editor.html                 # Visual test configuration editor
|
|-- Recorded Data/
|   +-- output.json                 # Test configuration (steps, browser, etc.)
|
|-- RobotFramework/
|   |-- tests/
|   |   |-- test_e2e.robot          # End-to-end test suite
|   |   |-- test_browser.robot      # Browser module tests
|   |   +-- test_stepIterator.robot  # Step iterator tests
|   |
|   |-- resources/
|   |   |-- browser.robot           # Browser launch and config
|   |   |-- jsonparser.robot        # JSON file parser
|   |   |-- stepExecutor.robot      # Single step dispatcher
|   |   |-- stepIterator.robot      # Step range iterator
|   |   |
|   |   |-- keywords/
|   |   |   |-- click.robot         # Click action handler
|   |   |   |-- input.robot         # Text input handler
|   |   |   |-- verify.robot        # Verification orchestrator
|   |   |   |-- verifyText.robot    # Text content verification
|   |   |   |-- verifyTag.robot     # Tag name verification
|   |   |   |-- verifyAttributes.robot  # Attribute verification
|   |   |   |-- calculate.robot     # Variable calculation/comparison
|   |   |   |-- wait.robot          # Wait strategies
|   |   |   +-- variableManager.robot   # Local variable store
|   |   |
|   |   +-- variables/
|   |       +-- paths.robot         # Project path constants
|   |
|   +-- libraries/
|       |-- ScreenshotHelper.py     # Before/during/after screenshot capture
|       +-- ReportGenerator.py      # Custom HTML report generator
|
|-- Website/
|   +-- ecommerce-test-playground.html  # Sample test application
|
|-- Reports/                        # Generated test reports (timestamped)
|
|-- setup.bat                       # Environment setup script
|-- test_e2e.bat                    # Run end-to-end tests
+-- requirements.txt                # Python dependencies
```

---

## Running Tests

### Run End-to-End Tests

```
test_e2e.bat
```

This script will:
1. Generate a timestamped report folder name (`Report DDMMYYYY HHMMSS`).
2. Create the folder under `Reports/`.
3. Execute `test_e2e.robot` which opens the browser, runs all steps from `output.json`, captures before/during/after screenshots, and generates the custom HTML report.
4. Output the report path when done.

After execution, open `Reports/<latest>/ag_autoframe_report.html` for the interactive report.

### Run Specific Tests

```bash
robot --test "Test Name" RobotFramework/tests/test_e2e.robot
```

### Run with Custom Output Directory

```bash
robot --outputdir "path/to/output" --variable REPORT_DIR:"path/to/output" RobotFramework/tests/test_e2e.robot
```

---

## Test Editor

The Test Editor (`TestEditor/editor.html`) is a browser-based visual interface for creating and editing test configurations. No JSON editing required.

### Getting Started

1. Open `TestEditor/editor.html` in any browser (Chrome recommended).
2. You will see the editor with a top bar, a step sidebar on the left, and the editing panel on the right.

### Loading an Existing Config

1. Click **Open JSON** in the top bar.
2. Navigate to `Recorded Data/output.json` (or any valid config JSON).
3. The sidebar populates with all steps grouped by section. The configuration panel shows browser settings.

### Creating a New Config

1. Click **New Config** in the top bar.
2. The editor resets with empty configuration fields and no steps.
3. Fill in the configuration panel (browser, headed mode, implicit wait, start URL).
4. Click **+ Add Step** to add your first step.

### Editing Configuration

The top of the editing panel shows the **Configuration** section with four fields:

| Field | Input Type | Options |
|---|---|---|
| Browser | Dropdown | Chrome, Edge, Safari |
| Headed Mode | Dropdown | True (visible), False (headless) |
| Implicit Wait (ms) | Number input | Any positive integer (e.g. 3000) |
| Start URL | Text input | Relative path (e.g. `ecommerce-test-playground.html`) or full URL (e.g. `https://www.google.com`) |

### Editing Steps

Click any step card in the sidebar to select it. The right panel shows all editable fields for that step:

**Basic Info:**
- **Section Name** -- Groups steps visually in the sidebar (e.g. "Login Page", "Search Watch").
- **Description** -- Free-text description of what the step does.
- **Action Type** -- Dropdown: `Click`, `Type / Input`, `Verify`, or `Calculate`.

**Element Targeting:**
- **Element DOM** -- The raw HTML of the target element. Paste from browser DevTools.
- **Element Text Content** -- The visible text of the element.
- **Element Tag Name** -- The HTML tag (e.g. `button`, `input`, `label`).
- **Element Attributes** -- Auto-populated from the DOM field. Each attribute shows as a name/value pair with a remove button.
- **XPath** -- The XPath selector used to locate the element. Auto-generated from DOM data or manually editable.

**Parent Element (optional):**
- **Parent Text Content**, **Parent Tag Name**, **Parent Attributes** -- Same as above but for the parent element. Used for context in complex DOM structures.

**Dynamic Elements:**
- **Is Dynamic** -- Toggle for elements that change (e.g. product cards with different prices).
- **Nth Identifier DOM** -- The DOM pattern used with nth-child targeting.
- **Nth Index** -- The index of the specific instance to target.

**Action-Specific Fields:**
- **Input Value** -- (Shown for `Type / Input` actions) The text to type into the element.
- **Verify DOM** -- (Shown for `Verify` actions) Add verification rules with text/tag/attribute checks and operators (`equalTo`, `contains`, `varContains`, `eleContains`).
- **Calculate** -- (Shown for `Calculate` actions) Configure variable1, operator, variable2, expected result, and result operator.

**Wait Configuration:**
- **Wait Type** -- Dropdown: `elementVisible`, `elementClickable`, `elementPresent`, `elementNotVisible`, `textPresent`, `pageLoad`, `custom`, or none.
- **Timeout (ms)** -- How long to wait before failing.

**Variable Storage:**
- **Save Variable** -- Enter a name to store the element's text content as `{{bb.local.YourName}}` for use in later steps.

**Execution Control:**
- **Skip** -- Dropdown: `No` (execute) or `Yes` (skip this step).
- **Stop on Failure** -- Dropdown: `Yes` (halt on error) or `No` (continue).

### Reordering Steps

Drag and drop step cards in the sidebar to reorder them. Step numbers automatically re-resolve in ascending order after each drag operation.

### Deleting Steps

Click the **x** icon on any step card. A confirmation dialog appears showing which step will be deleted. Step numbers re-resolve after deletion.

### Saving and Downloading

- **Save** -- Saves changes to the currently loaded file. A confirmation dialog shows a summary of what changed. The change list is scrollable, so even with a large number of modifications the dialog remains fully usable.
- **Download** -- Downloads the config as a new JSON file. Use this to create a copy or export for the first time.

### Supported Step Fields

| Field | Description |
|---|---|
| `actionType` | Click, Type / Input, Verify, Calculate |
| `xpath` | XPath selector for the target element |
| `elementTextContent` | Text content of the element |
| `elementTagName` | HTML tag name |
| `elementAttributes` | List of `[attribute_name, attribute_value]` pairs |
| `inputValue` | Value to type (for input steps) |
| `save` | Variable name to store element text |
| `wait` | Wait strategy and timeout |
| `verifyDOM` | Verification rules (text, tag, attributes with operators) |
| `skip` | Yes/No -- skip this step |
| `stopOnFailure` | Yes/No -- halt execution on failure |

---

## JSON Configuration

The framework reads test definitions from a JSON file (default: `Recorded Data/output.json`).

### Top-level Fields

```json
{
  "browser": "Chrome",
  "headed": true,
  "implicitWait": 3000,
  "startURL": "ecommerce-test-playground.html",
  "steps": [ ... ]
}
```

| Field | Type | Description |
|---|---|---|
| `browser` | string | `Chrome`, `Edge`, or `Safari` |
| `headed` | boolean | `true` = visible browser, `false` = headless |
| `implicitWait` | number | Default wait timeout in milliseconds |
| `startURL` | string | Relative path to HTML file in `Website/` or full URL (`https://...`) |
| `steps` | array | Ordered list of test step objects |

### Step Object

Each step has these fields:

```json
{
  "stepNumber": 1,
  "sectionName": "Login Page",
  "description": "Verify email label",
  "actionType": "Verify",
  "elementDOM": "<label class='form-label'>...</label>",
  "elementTextContent": "Email",
  "elementTagName": "label",
  "elementAttributes": [["class", "form-label"]],
  "parentTextContent": "",
  "parentTagName": "div",
  "parentAttributes": [["class", "mb-3"]],
  "xpath": "//label[@class='form-label'][contains(.,'Email')]",
  "isDynamic": false,
  "nthIdentifierDOM": "",
  "nthIndex": "",
  "inputValue": "",
  "save": "",
  "wait": [{"waitType": "", "Timeout": 0}],
  "verifyDOM": [],
  "calculate": {},
  "skip": "No",
  "stopOnFailure": "Yes"
}
```

### Verification Operators

Every verification method supports four operators:

| Operator | Description |
|---|---|
| `equalTo` | Exact match |
| `contains` | Actual value contains the expected string |
| `varContains` | Stored variable value contains the element's value |
| `eleContains` | Element's value contains the stored variable value |

### Variable References

Steps can store element text into local variables using the `save` field, and reference them later with `{{bb.local.VariableName}}`.

---

## Framework Architecture

```
output.json
    |
    v
jsonparser.robot          -- Parses JSON config
    |
    v
browser.robot             -- Opens browser (Chrome/Edge/Safari, headed/headless)
    |
    v
stepIterator.robot        -- Loops through steps in a given range
    |
    v
stepExecutor.robot        -- Dispatches each step by actionType
    |
    +-- click.robot       -- Click element, optionally save text
    +-- input.robot       -- Clear + type into element
    +-- verify.robot      -- Orchestrates verification checks
    |   +-- verifyText.robot
    |   +-- verifyTag.robot
    |   +-- verifyAttributes.robot
    +-- calculate.robot   -- Compare stored variables
    +-- wait.robot        -- Wait strategies before actions
    +-- variableManager.robot  -- Store/retrieve local variables
    |
    v
ScreenshotHelper.py       -- Captures before/during/after screenshots
    |
    v
ReportGenerator.py        -- Generates custom HTML report
```

### Execution Flow

1. `test_e2e.robot` loads the JSON config via `jsonparser.robot`.
2. `browser.robot` opens the configured browser.
3. `stepIterator.robot` loops through steps in the specified range.
4. For each step:
   - `stepExecutor.robot` checks `skip` and `stopOnFailure` flags.
   - Captures a **before** screenshot.
   - Highlights the target element and captures a **during** screenshot.
   - Dispatches to the appropriate keyword module (click/input/verify/calculate).
   - Captures an **after** screenshot.
   - Snapshots the current variable store.
5. `ReportGenerator.py` builds the final HTML report with all data.

### Wait Strategies

| Strategy | Description |
|---|---|
| `elementVisible` | Wait until element is visible |
| `elementClickable` | Wait until element is visible and enabled |
| `elementPresent` | Wait until element exists in DOM |
| `elementNotVisible` | Wait until element disappears |
| `textPresent` | Wait until element contains text |
| `pageLoad` | Wait for `document.readyState == "complete"` |
| `custom` | Plain sleep for the specified timeout |

---

## Reports

Each test run generates a timestamped folder under `Reports/`:

```
Reports/
+-- Report 20032026 190821/
    |-- ag_autoframe_report.html   # Custom interactive report
    |-- log.html               # Robot Framework detailed log
    |-- report.html            # Robot Framework summary
    |-- output.xml             # Raw XML output
    +-- screenshots/
        |-- step_1_before.png
        |-- step_1_during.png
        |-- step_1_after.png
        |-- step_2_before.png
        +-- ...
```

### Custom Report (`ag_autoframe_report.html`)

- **Split-panel layout** -- Step cards on the left, screenshot viewer on the right.
- **Configuration display** -- Toggle to view browser, URL, and test settings.
- **Summary bar** -- Total, passed, failed, and skipped counts with filter buttons.
- **Step cards** -- Click to view details and screenshots. Click again to collapse.
- **Screenshot tabs** -- Switch between Before, During (element highlighted), and After.
- **Variable snapshots** -- See stored variable values at each step.
- **Lightbox** -- Click any screenshot to view full-size.
- **Filters** -- Show All / Passed / Failed / Skipped steps.
- **Expand/Collapse All** -- Bulk toggle step details.

---

## Modules

### Action Modules

| Module | File | Description |
|---|---|---|
| Click | `keywords/click.robot` | Clicks an element. Optionally saves text to a variable before clicking. |
| Input | `keywords/input.robot` | Clears and types a value into an input element. |
| Verify | `keywords/verify.robot` | Orchestrates text, tag, and attribute verifications. |
| Calculate | `keywords/calculate.robot` | Compares two stored variables with operators (`==`, `!=`, `>`, `<`, `>=`, `<=`, `contains`). |

### Support Modules

| Module | File | Description |
|---|---|---|
| Wait | `keywords/wait.robot` | 7 wait strategies before actions. |
| Variable Manager | `keywords/variableManager.robot` | Store, retrieve, and resolve `{{bb.local.*}}` variable references. |
| Screenshot Helper | `libraries/ScreenshotHelper.py` | Captures before/during/after screenshots with element highlighting. |
| Report Generator | `libraries/ReportGenerator.py` | Builds the custom HTML report with embedded screenshots. |

