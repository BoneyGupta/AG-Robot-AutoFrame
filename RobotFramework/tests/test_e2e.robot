*** Settings ***
Library     ../libraries/ScreenshotHelper.py
Library     ../libraries/ReportGenerator.py
Resource    ../resources/browser.robot
Resource    ../resources/jsonparser.robot
Resource    ../resources/stepIterator.robot
Resource    ../resources/keywords/variableManager.robot
Resource    ../resources/variables/paths.robot

Suite Setup       Initialize Variable Store
Suite Teardown    Close All Browsers

*** Test Cases ***
End To End Test All Steps
    [Documentation]    Runs all steps from output.json against the live browser.
    ...                Captures before/during/after screenshots for each step.
    ...                Generates a custom HTML report with toggleable details.

    # Determine report output directory (passed via --variable REPORT_DIR:<path> or default)
    ${report_dir_set}=    Run Keyword And Return Status    Variable Should Exist    ${REPORT_DIR}
    IF    not ${report_dir_set}
        ${timestamp}=    Evaluate    __import__('datetime').datetime.now().strftime('%d%m%Y %H%M%S')
        ${report_dir}=    Set Variable    ${REPORTS_DIR}${/}Report ${timestamp}
    ELSE
        ${report_dir}=    Set Variable    ${REPORT_DIR}
    END

    # Create screenshots subdirectory
    ${screenshot_dir}=    Set Variable    ${report_dir}${/}screenshots
    Create Directory    ${screenshot_dir}
    ScreenshotHelper.Set Screenshot Directory    ${screenshot_dir}

    # Open browser and parse config
    ${browser}    ${window}=    Open Browser From Config    ${CONFIG_PATH}
    ${json_data}=    Parse JSON Config    ${CONFIG_PATH}

    # Count total steps
    ${steps}=    Set Variable    ${json_data}[steps]
    ${step_count}=    Get Length    ${steps}
    ${end_step}=    Evaluate    ${step_count} + 1

    # Run all steps (continue on failure to capture all results)
    ${browser_ctx}    ${executed}    ${failed}    ${results}=    Iterate Steps
    ...    ${browser}    ${json_data}    1    ${end_step}    continue_on_failure=${True}

    Log    Executed: ${executed}, Failed: ${failed}

    # Generate custom HTML report
    ${report_path}=    Generate Report    ${report_dir}    ${CONFIG_PATH}    ${results}    ${executed}    ${failed}

    Log    Custom report: ${report_path}

    # Assert no failures
    Should Be Equal As Integers    ${failed}    0    msg=${failed} steps failed out of ${executed}
