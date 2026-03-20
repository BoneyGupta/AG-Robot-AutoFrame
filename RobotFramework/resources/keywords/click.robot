*** Settings ***
Library    SeleniumLibrary
Library    String
Resource   variableManager.robot
Resource   wait.robot

*** Keywords ***
Execute Click
    [Documentation]    Clicks on the element identified by xpath.
    ...                Optionally saves the element's text content to a local variable.
    [Arguments]    ${step_data}

    ${xpath}=    Set Variable    ${step_data}[xpath]
    ${save}=     Set Variable    ${step_data}[save]
    ${wait}=     Set Variable    ${step_data}[wait]

    # Handle any wait strategy before acting
    Handle Wait    ${wait}    ${xpath}

    # If save is specified, capture text before clicking
    IF    '${save}' != ''
        ${text}=    Get Text    xpath:${xpath}
        Store Variable    ${save}    ${text}
    END

    # Click the element
    TRY
        Click Element    xpath:${xpath}
        ${step_num}=    Set Variable    ${step_data}[stepNumber]
        Log    Step ${step_num}: Clicked element at ${xpath}
    EXCEPT    AS    ${error}
        ${step_num}=    Set Variable    ${step_data}[stepNumber]
        Fail    Step ${step_num}: Click failed on '${xpath}': ${error}
    END
