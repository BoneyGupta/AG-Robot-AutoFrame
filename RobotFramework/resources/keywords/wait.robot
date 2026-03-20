*** Settings ***
Library    SeleniumLibrary
Library    String

*** Keywords ***
Handle Wait
    [Documentation]    Executes the appropriate wait strategy based on the step's wait configuration.
    ...                Accepts the wait list from the step data and the element xpath.
    [Arguments]    ${wait_list}    ${xpath}=${NONE}

    FOR    ${wait_config}    IN    @{wait_list}
        ${wait_type}=    Set Variable    ${wait_config}[waitType]
        ${timeout}=      Set Variable    ${wait_config}[Timeout]

        IF    '${wait_type}' == '' or '${wait_type}' == 'none'
            Log    No wait required.
        ELSE IF    '${wait_type}' == 'elementVisible'
            Wait For Element Visible    ${xpath}    ${timeout}
        ELSE IF    '${wait_type}' == 'elementClickable'
            Wait For Element Clickable    ${xpath}    ${timeout}
        ELSE IF    '${wait_type}' == 'elementPresent'
            Wait For Element Present    ${xpath}    ${timeout}
        ELSE IF    '${wait_type}' == 'elementNotVisible'
            Wait For Element Not Visible    ${xpath}    ${timeout}
        ELSE IF    '${wait_type}' == 'textPresent'
            Wait For Text Present    ${xpath}    ${timeout}
        ELSE IF    '${wait_type}' == 'pageLoad'
            Wait For Page Load    ${timeout}
        ELSE IF    '${wait_type}' == 'custom'
            Wait For Custom Timeout    ${timeout}
        ELSE
            Log    Unknown wait type '${wait_type}', skipping.    level=WARN
        END
    END

Wait For Element Visible
    [Documentation]    Waits until the element identified by xpath is visible.
    [Arguments]    ${xpath}    ${timeout}
    ${timeout_sec}=    Evaluate    ${timeout} / 1000
    Wait Until Element Is Visible    xpath:${xpath}    timeout=${timeout_sec}s

Wait For Element Clickable
    [Documentation]    Waits until the element identified by xpath is enabled and visible.
    [Arguments]    ${xpath}    ${timeout}
    ${timeout_sec}=    Evaluate    ${timeout} / 1000
    Wait Until Element Is Visible    xpath:${xpath}    timeout=${timeout_sec}s
    Wait Until Element Is Enabled    xpath:${xpath}    timeout=${timeout_sec}s

Wait For Element Present
    [Documentation]    Waits until the element identified by xpath exists in the DOM.
    [Arguments]    ${xpath}    ${timeout}
    ${timeout_sec}=    Evaluate    ${timeout} / 1000
    Wait Until Page Contains Element    xpath:${xpath}    timeout=${timeout_sec}s

Wait For Element Not Visible
    [Documentation]    Waits until the element identified by xpath is no longer visible.
    [Arguments]    ${xpath}    ${timeout}
    ${timeout_sec}=    Evaluate    ${timeout} / 1000
    Wait Until Element Is Not Visible    xpath:${xpath}    timeout=${timeout_sec}s

Wait For Text Present
    [Documentation]    Waits until the element identified by xpath contains any text.
    [Arguments]    ${xpath}    ${timeout}
    ${timeout_sec}=    Evaluate    ${timeout} / 1000
    Wait Until Element Is Visible    xpath:${xpath}    timeout=${timeout_sec}s
    Wait Until Element Contains    xpath:${xpath}    ${EMPTY}    timeout=${timeout_sec}s

Wait For Page Load
    [Documentation]    Waits for the page to finish loading by checking document.readyState.
    [Arguments]    ${timeout}
    ${timeout_sec}=    Evaluate    ${timeout} / 1000
    Set Selenium Timeout    ${timeout_sec}s
    Wait For Condition    return document.readyState == "complete"    timeout=${timeout_sec}s

Wait For Custom Timeout
    [Documentation]    Pauses execution for the specified timeout in milliseconds.
    [Arguments]    ${timeout}
    ${timeout_sec}=    Evaluate    ${timeout} / 1000
    Sleep    ${timeout_sec}s    reason=Custom wait timeout of ${timeout}ms
