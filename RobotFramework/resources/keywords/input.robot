*** Settings ***
Library    SeleniumLibrary
Library    String
Resource   wait.robot

*** Keywords ***
Execute Input
    [Documentation]    Types the inputValue into the element identified by xpath.
    [Arguments]    ${step_data}

    ${xpath}=        Set Variable    ${step_data}[xpath]
    ${input_value}=  Set Variable    ${step_data}[inputValue]
    ${wait}=         Set Variable    ${step_data}[wait]

    # Handle any wait strategy before acting
    Handle Wait    ${wait}    ${xpath}

    TRY
        Clear Element Text    xpath:${xpath}
        Input Text    xpath:${xpath}    ${input_value}
        ${step_num}=    Set Variable    ${step_data}[stepNumber]
        Log    Step ${step_num}: Typed '${input_value}' into ${xpath}
    EXCEPT    AS    ${error}
        ${step_num}=    Set Variable    ${step_data}[stepNumber]
        Fail    Step ${step_num}: Input failed on '${xpath}': ${error}
    END
