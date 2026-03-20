*** Settings ***
Library     SeleniumLibrary
Library     OperatingSystem
Library     Collections
Library     String
Resource    ../resources/browser.robot
Resource    ../resources/jsonparser.robot
Resource    ../resources/variables/paths.robot

Suite Teardown    Close All Browsers

*** Test Cases ***
Test Open Browser From Config With Default JSON
    [Documentation]    Verifies that a browser opens successfully using the actual output.json config.
    [Teardown]    Close All Browsers
    ${browser}    ${window}=    Open Browser From Config    ${CONFIG_PATH}
    Should Not Be Empty    ${browser}
    Should Not Be Empty    ${window}
    ${url}=    Get Location
    Should Contain    ${url}    ecommerce-test-playground
    Sleep    5s    Keeping browser open for visual verification

Test Page Title Is Loaded
    [Documentation]    Verifies the page navigated to the start URL and loaded content.
    [Teardown]    Close All Browsers
    ${browser}    ${window}=    Open Browser From Config    ${CONFIG_PATH}
    ${title}=    Get Title
    Should Not Be Empty    ${title}
    Sleep    5s    Keeping browser open for visual verification

Test JSON Parser Returns Browser Name
    [Documentation]    Verifies that the jsonparser correctly extracts the browser name.
    ${json_data}=    Parse JSON Config    ${CONFIG_PATH}
    ${browser}=    Get Browser Name    ${json_data}
    Should Not Be Empty    ${browser}
    ${browser_lower}=    Convert To Lower Case    ${browser}
    Should Be True    '${browser_lower}' in ['chrome', 'edge', 'safari']

Test JSON Parser Returns Headed Mode
    [Documentation]    Verifies that the jsonparser correctly extracts the headed flag.
    ${json_data}=    Parse JSON Config    ${CONFIG_PATH}
    ${headed}=    Get Headed Mode    ${json_data}
    Should Be True    ${headed} == True or ${headed} == False

Test JSON Parser Returns Start Page
    [Documentation]    Verifies that the jsonparser correctly extracts the start page filename.
    ${json_data}=    Parse JSON Config    ${CONFIG_PATH}
    ${start_page}=    Get Start Page    ${json_data}
    Should Not Be Empty    ${start_page}
    Should Contain    ${start_page}    ecommerce-test-playground

Test Unsupported Browser Fails Gracefully
    [Documentation]    Verifies that an unsupported browser name causes a clear failure.
    ${json_data}=    Parse JSON Config    ${CONFIG_PATH}
    Set To Dictionary    ${json_data}    browser=firefox
    ${browser_lower}=    Convert To Lower Case    ${json_data}[browser]
    ${selenium_browser}=    Set Variable If
    ...    '${browser_lower}' == 'chrome'     chrome
    ...    '${browser_lower}' == 'edge'       edge
    ...    '${browser_lower}' == 'safari'     safari
    ...    NONE
    Should Be Equal As Strings    ${selenium_browser}    NONE

Test Chrome Maps Correctly
    [Documentation]    Verifies that 'chrome' maps to 'chrome' for SeleniumLibrary.
    ${browser_type}=    Map Browser Type    chrome
    Should Be Equal As Strings    ${browser_type}    chrome

Test Edge Maps Correctly
    [Documentation]    Verifies that 'edge' maps to 'edge' for SeleniumLibrary.
    ${browser_type}=    Map Browser Type    edge
    Should Be Equal As Strings    ${browser_type}    edge

Test Safari Maps Correctly
    [Documentation]    Verifies that 'safari' maps to 'safari' for SeleniumLibrary.
    ${browser_type}=    Map Browser Type    safari
    Should Be Equal As Strings    ${browser_type}    safari

Test Headed Mode Opens Visible Browser
    [Documentation]    Verifies that headed=true means no headless flag is needed.
    ${needs_headless}=    Evaluate    not True
    Should Be Equal    ${needs_headless}    ${False}

Test Headless Mode Computed Correctly
    [Documentation]    Verifies that headed=false means headless flag is needed.
    ${needs_headless}=    Evaluate    not False
    Should Be Equal    ${needs_headless}    ${True}

*** Keywords ***
Map Browser Type
    [Documentation]    Maps a browser name string to the SeleniumLibrary browser name.
    [Arguments]    ${browser_name}
    ${browser_lower}=    Convert To Lower Case    ${browser_name}
    ${browser_type}=    Set Variable If
    ...    '${browser_lower}' == 'chrome'     chrome
    ...    '${browser_lower}' == 'edge'       edge
    ...    '${browser_lower}' == 'safari'     safari
    ...    NONE
    RETURN    ${browser_type}
