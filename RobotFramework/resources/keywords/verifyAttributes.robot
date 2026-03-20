*** Settings ***
Library    SeleniumLibrary
Library    String
Library    Collections
Resource   variableManager.robot

*** Keywords ***
Verify Element Attributes
    [Documentation]    Verifies attributes of an element using the specified operators.
    ...                Accepts the attributes dict from verifyDOM where each key is an
    ...                attribute name and value is [expectedValue, operator].
    ...                Operators: equalTo, contains, varContains, eleContains.
    ...                Decodes HTML entities in expected values before comparison.
    [Arguments]    ${xpath}    ${attributes_dict}    ${step_number}

    ${attr_names}=    Get Dictionary Keys    ${attributes_dict}

    FOR    ${attr_name}    IN    @{attr_names}
        ${attr_config}=    Get From Dictionary    ${attributes_dict}    ${attr_name}
        ${expected_raw}=   Set Variable    ${attr_config}[0]
        ${operator}=       Set Variable    ${attr_config}[1]

        # Decode HTML entities in expected value
        ${expected_value}=    Evaluate    __import__('html').unescape($expected_raw)

        ${actual_value}=    Get Element Attribute    xpath:${xpath}    ${attr_name}
        # Handle None attributes
        ${actual_value}=    Set Variable If    $actual_value is None    ${EMPTY}    ${actual_value}

        IF    '${operator}' == 'equalTo'
            ${actual_lower}=      Convert To Lower Case    ${actual_value}
            ${expected_lower}=    Convert To Lower Case    ${expected_value}
            Should Be Equal As Strings    ${actual_lower}    ${expected_lower}
            ...    Step ${step_number}: Attribute '${attr_name}' mismatch. Expected '${expected_value}' but got '${actual_value}'

        ELSE IF    '${operator}' == 'contains'
            ${actual_lower}=      Convert To Lower Case    ${actual_value}
            ${expected_lower}=    Convert To Lower Case    ${expected_value}
            Should Contain    ${actual_lower}    ${expected_lower}
            ...    Step ${step_number}: Attribute '${attr_name}' value '${actual_value}' does not contain '${expected_value}'

        ELSE IF    '${operator}' == 'varContains'
            # Stored variable text CONTAINS the element's attribute value
            ${var_value}=    Resolve Variable Reference    ${expected_value}
            ${var_lower}=       Convert To Lower Case    ${var_value}
            ${actual_lower}=    Convert To Lower Case    ${actual_value}
            Should Contain    ${var_lower}    ${actual_lower}
            ...    Step ${step_number}: Variable '${var_value}' does not contain attribute '${attr_name}' value '${actual_value}'

        ELSE IF    '${operator}' == 'eleContains'
            # Element's attribute value CONTAINS the stored variable text
            ${var_value}=    Resolve Variable Reference    ${expected_value}
            ${var_lower}=       Convert To Lower Case    ${var_value}
            ${actual_lower}=    Convert To Lower Case    ${actual_value}
            Should Contain    ${actual_lower}    ${var_lower}
            ...    Step ${step_number}: Attribute '${attr_name}' value '${actual_value}' does not contain variable '${var_value}'

        ELSE
            Fail    Step ${step_number}: Unknown attribute verify operator '${operator}' for '${attr_name}'
        END

        Log    Step ${step_number}: Attribute '${attr_name}' verification passed [${operator}]
    END
