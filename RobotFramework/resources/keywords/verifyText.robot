*** Settings ***
Library    SeleniumLibrary
Library    String
Resource   variableManager.robot

*** Keywords ***
Verify Text Content
    [Documentation]    Verifies the text content of an element using the specified operator.
    ...                Operators: equalTo, contains, varContains, eleContains.
    ...                Uses case-insensitive comparison for contains/equalTo.
    [Arguments]    ${xpath}    ${expected_text}    ${operator}    ${step_number}

    ${actual_text}=    Get Text    xpath:${xpath}
    # Normalize whitespace in actual text (collapse newlines/spaces)
    ${actual_normalized}=    Evaluate    ' '.join($actual_text.split())

    IF    '${operator}' == 'equalTo'
        ${actual_lower}=      Convert To Lower Case    ${actual_normalized}
        ${expected_lower}=    Convert To Lower Case    ${expected_text}
        Should Be Equal As Strings    ${actual_lower}    ${expected_lower}
        ...    Step ${step_number}: Text mismatch. Expected '${expected_text}' but got '${actual_normalized}'

    ELSE IF    '${operator}' == 'contains'
        ${actual_lower}=      Convert To Lower Case    ${actual_normalized}
        ${expected_lower}=    Convert To Lower Case    ${expected_text}
        Should Contain    ${actual_lower}    ${expected_lower}
        ...    Step ${step_number}: Element text '${actual_normalized}' does not contain '${expected_text}'

    ELSE IF    '${operator}' == 'varContains'
        # Stored variable text CONTAINS the element's text content
        ${var_value}=    Resolve Variable Reference    ${expected_text}
        ${var_lower}=       Convert To Lower Case    ${var_value}
        ${actual_lower}=    Convert To Lower Case    ${actual_normalized}
        Should Contain    ${var_lower}    ${actual_lower}
        ...    Step ${step_number}: Variable value '${var_value}' does not contain element text '${actual_normalized}'

    ELSE IF    '${operator}' == 'eleContains'
        # Element's text content CONTAINS the stored variable text
        ${var_value}=    Resolve Variable Reference    ${expected_text}
        ${var_lower}=       Convert To Lower Case    ${var_value}
        ${actual_lower}=    Convert To Lower Case    ${actual_normalized}
        Should Contain    ${actual_lower}    ${var_lower}
        ...    Step ${step_number}: Element text '${actual_normalized}' does not contain variable value '${var_value}'

    ELSE
        Fail    Step ${step_number}: Unknown text verify operator '${operator}'
    END

    Log    Step ${step_number}: Text verification passed [${operator}]
