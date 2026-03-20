*** Settings ***
Library    String
Library    Collections
Resource   variableManager.robot

*** Keywords ***
Execute Calculate
    [Documentation]    Performs a calculation/comparison between two variable values.
    ...                Resolves variable references, applies the operator, and checks
    ...                the result against the expected outcome.
    [Arguments]    ${step_data}

    ${step_num}=       Set Variable    ${step_data}[stepNumber]
    ${calc}=           Set Variable    ${step_data}[calculate]
    ${var1_ref}=       Set Variable    ${calc}[variable1]
    ${operator}=       Set Variable    ${calc}[operator]
    ${var2_ref}=       Set Variable    ${calc}[variable2]
    ${expected}=       Set Variable    ${calc}[expectedResult]
    ${result_op}=      Set Variable    ${calc}[resultOperator]

    # Resolve variable references
    ${val1}=    Resolve Variable Reference    ${var1_ref}
    ${val2}=    Resolve Variable Reference    ${var2_ref}

    Log    Step ${step_num}: Comparing '${val1}' ${operator} '${val2}' (expected: ${expected})

    # Apply the operator
    ${result}=    Set Variable    ${EMPTY}
    IF    '${operator}' == '=='
        # Try string comparison first, fall back to numeric comparison
        ${is_equal}=    Run Keyword And Return Status    Should Be Equal As Strings    ${val1}    ${val2}
        IF    not ${is_equal}
            # Extract numeric values and compare (handles $595 vs $595 USD)
            ${num1}=    Evaluate    float(''.join(c for c in $val1 if c.isdigit() or c == '.'))
            ${num2}=    Evaluate    float(''.join(c for c in $val2 if c.isdigit() or c == '.'))
            ${is_equal}=    Evaluate    ${num1} == ${num2}
        END
        ${result}=    Set Variable If    ${is_equal}    true    false
    ELSE IF    '${operator}' == '!='
        ${is_equal}=    Run Keyword And Return Status    Should Be Equal As Strings    ${val1}    ${val2}
        IF    not ${is_equal}
            ${num1}=    Evaluate    float(''.join(c for c in $val1 if c.isdigit() or c == '.'))
            ${num2}=    Evaluate    float(''.join(c for c in $val2 if c.isdigit() or c == '.'))
            ${is_equal}=    Evaluate    ${num1} == ${num2}
        END
        ${result}=    Set Variable If    ${is_equal}    false    true
    ELSE IF    '${operator}' == '>'
        ${num1}=    Evaluate    float(''.join(c for c in '${val1}' if c.isdigit() or c == '.'))
        ${num2}=    Evaluate    float(''.join(c for c in '${val2}' if c.isdigit() or c == '.'))
        ${is_greater}=    Evaluate    ${num1} > ${num2}
        ${result}=    Set Variable If    ${is_greater}    true    false
    ELSE IF    '${operator}' == '<'
        ${num1}=    Evaluate    float(''.join(c for c in '${val1}' if c.isdigit() or c == '.'))
        ${num2}=    Evaluate    float(''.join(c for c in '${val2}' if c.isdigit() or c == '.'))
        ${is_less}=    Evaluate    ${num1} < ${num2}
        ${result}=    Set Variable If    ${is_less}    true    false
    ELSE IF    '${operator}' == '>='
        ${num1}=    Evaluate    float(''.join(c for c in '${val1}' if c.isdigit() or c == '.'))
        ${num2}=    Evaluate    float(''.join(c for c in '${val2}' if c.isdigit() or c == '.'))
        ${is_gte}=    Evaluate    ${num1} >= ${num2}
        ${result}=    Set Variable If    ${is_gte}    true    false
    ELSE IF    '${operator}' == '<='
        ${num1}=    Evaluate    float(''.join(c for c in '${val1}' if c.isdigit() or c == '.'))
        ${num2}=    Evaluate    float(''.join(c for c in '${val2}' if c.isdigit() or c == '.'))
        ${is_lte}=    Evaluate    ${num1} <= ${num2}
        ${result}=    Set Variable If    ${is_lte}    true    false
    ELSE IF    '${operator}' == 'contains'
        ${has}=    Run Keyword And Return Status    Should Contain    ${val1}    ${val2}
        ${result}=    Set Variable If    ${has}    true    false
    ELSE
        Fail    Step ${step_num}: Unknown calculate operator '${operator}'
    END

    # Check result against expected
    IF    '${result_op}' == 'equalTo'
        Should Be Equal As Strings    ${result}    ${expected}
        ...    Step ${step_num}: Calculation result '${result}' does not equal expected '${expected}'. (${val1} ${operator} ${val2})
    ELSE IF    '${result_op}' == 'contains'
        Should Contain    ${result}    ${expected}
        ...    Step ${step_num}: Calculation result '${result}' does not contain '${expected}'
    ELSE
        Fail    Step ${step_num}: Unknown resultOperator '${result_op}'
    END

    Log    Step ${step_num}: Calculation passed. '${val1}' ${operator} '${val2}' = ${result} (expected: ${expected})
