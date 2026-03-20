*** Settings ***
Library    SeleniumLibrary
Library    String
Resource   variableManager.robot

*** Keywords ***
Verify Tag Name
    [Documentation]    Verifies the tag name of an element using the specified operator.
    ...                Operators: equalTo, contains, varContains, eleContains.
    [Arguments]    ${xpath}    ${expected_tag}    ${operator}    ${step_number}

    ${element}=    Get WebElement    xpath:${xpath}
    ${actual_tag}=    Evaluate    $element.tag_name.lower()

    IF    '${operator}' == 'equalTo'
        ${expected_lower}=    Convert To Lower Case    ${expected_tag}
        Should Be Equal As Strings    ${actual_tag}    ${expected_lower}
        ...    Step ${step_number}: Tag mismatch. Expected '${expected_lower}' but got '${actual_tag}'

    ELSE IF    '${operator}' == 'contains'
        ${expected_lower}=    Convert To Lower Case    ${expected_tag}
        Should Contain    ${actual_tag}    ${expected_lower}
        ...    Step ${step_number}: Tag '${actual_tag}' does not contain '${expected_lower}'

    ELSE IF    '${operator}' == 'varContains'
        # Stored variable text CONTAINS the element's tag name
        ${var_value}=    Resolve Variable Reference    ${expected_tag}
        ${var_lower}=    Convert To Lower Case    ${var_value}
        Should Contain    ${var_lower}    ${actual_tag}
        ...    Step ${step_number}: Variable value '${var_value}' does not contain tag '${actual_tag}'

    ELSE IF    '${operator}' == 'eleContains'
        # Element's tag name CONTAINS the stored variable text
        ${var_value}=    Resolve Variable Reference    ${expected_tag}
        ${var_lower}=    Convert To Lower Case    ${var_value}
        Should Contain    ${actual_tag}    ${var_lower}
        ...    Step ${step_number}: Tag '${actual_tag}' does not contain variable value '${var_value}'

    ELSE
        Fail    Step ${step_number}: Unknown tag verify operator '${operator}'
    END

    Log    Step ${step_number}: Tag verification passed [${operator}]
