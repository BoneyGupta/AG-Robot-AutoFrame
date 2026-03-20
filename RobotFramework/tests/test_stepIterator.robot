*** Settings ***
Library     SeleniumLibrary
Library     Collections
Library     OperatingSystem
Library     ../libraries/ScreenshotHelper.py
Resource    ../resources/browser.robot
Resource    ../resources/jsonparser.robot
Resource    ../resources/stepIterator.robot
Resource    ../resources/keywords/variableManager.robot
Resource    ../resources/variables/paths.robot

Suite Setup       Run Keywords    Initialize Variable Store    AND    Setup Screenshot Directory
Suite Teardown    Close All Browsers

*** Keywords ***
Setup Screenshot Directory
    ${report_dir_set}=    Run Keyword And Return Status    Variable Should Exist    ${REPORT_DIR}
    IF    not ${report_dir_set}
        ${timestamp}=    Evaluate    __import__('datetime').datetime.now().strftime('%d%m%Y %H%M%S')
        ${report_path}=    Set Variable    ${REPORTS_DIR}${/}Report ${timestamp}
        Set Suite Variable    $report_dir    ${report_path}
    ELSE
        Set Suite Variable    $report_dir    ${REPORT_DIR}
    END
    ${report_dir_val}=    Get Variable Value    $report_dir
    ${screenshot_dir}=    Set Variable    ${report_dir_val}${/}screenshots
    Create Directory    ${screenshot_dir}
    ScreenshotHelper.Set Screenshot Directory    ${screenshot_dir}

*** Test Cases ***
Test Iterate All Steps With Browser
    [Documentation]    Opens browser and runs all 23 steps.
    ${browser}    ${window}=    Open Browser From Config    ${CONFIG_PATH}
    ${json_data}=    Parse JSON Config    ${CONFIG_PATH}
    ${browser_ctx}    ${executed}    ${failed}    ${results}=    Iterate Steps    ${browser}    ${json_data}    1    24
    Should Be Equal As Integers    ${executed}    23
    Should Be Equal As Integers    ${failed}    0
    Should Be Equal    ${browser_ctx}    ${browser}

Test Iterate Subset With Browser
    [Documentation]    Opens browser and runs steps 1 through 4 (verify login page).
    ${browser}    ${window}=    Open Browser From Config    ${CONFIG_PATH}
    ${json_data}=    Parse JSON Config    ${CONFIG_PATH}
    ${browser_ctx}    ${executed}    ${failed}    ${results}=    Iterate Steps    ${browser}    ${json_data}    1    5
    Should Be Equal As Integers    ${executed}    4
    Should Be Equal As Integers    ${failed}    0

Test Iterate Empty Range
    [Documentation]    Verifies that no steps are iterated when start equals end.
    ${json_data}=    Parse JSON Config    ${CONFIG_PATH}
    ${browser_ctx}    ${executed}    ${failed}    ${results}=    Iterate Steps    none    ${json_data}    5    5
    Should Be Equal As Integers    ${executed}    0
    Should Be Equal As Integers    ${failed}    0

Test Iterate Out Of Range
    [Documentation]    Verifies that no steps are iterated when range is beyond step numbers.
    ${json_data}=    Parse JSON Config    ${CONFIG_PATH}
    ${browser_ctx}    ${executed}    ${failed}    ${results}=    Iterate Steps    none    ${json_data}    100    200
    Should Be Equal As Integers    ${executed}    0
    Should Be Equal As Integers    ${failed}    0

Test Browser Context Returned
    [Documentation]    Verifies the browser context is passed through in the return value.
    ${json_data}=    Parse JSON Config    ${CONFIG_PATH}
    ${browser_ctx}    ${executed}    ${failed}    ${results}=    Iterate Steps    my_browser    ${json_data}    50    51
    Should Be Equal    ${browser_ctx}    my_browser
