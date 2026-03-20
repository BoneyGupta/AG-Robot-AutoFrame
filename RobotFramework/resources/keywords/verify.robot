*** Settings ***
Library    SeleniumLibrary
Library    Collections
Library    String
Resource   verifyText.robot
Resource   verifyTag.robot
Resource   verifyAttributes.robot
Resource   variableManager.robot
Resource   wait.robot

*** Keywords ***
Execute Verify
    [Documentation]    Orchestrates all verification checks for a step.
    ...                Iterates through verifyDOM entries and delegates to
    ...                verifyText, verifyTag, and verifyAttributes as needed.
    ...                Optionally saves the element's text content to a local variable.
    [Arguments]    ${step_data}

    ${xpath}=        Set Variable    ${step_data}[xpath]
    ${step_num}=     Set Variable    ${step_data}[stepNumber]
    ${verify_dom}=   Set Variable    ${step_data}[verifyDOM]
    ${save}=         Set Variable    ${step_data}[save]
    ${wait}=         Set Variable    ${step_data}[wait]

    # Handle any wait strategy before verifying
    Handle Wait    ${wait}    ${xpath}

    # If save is specified, capture text content
    IF    '${save}' != ''
        ${text}=    Get Text    xpath:${xpath}
        Store Variable    ${save}    ${text}
    END

    # Iterate through each verifyDOM entry
    FOR    ${verify_entry}    IN    @{verify_dom}
        # Verify text content if present
        ${has_text}=    Run Keyword And Return Status
        ...    Dictionary Should Contain Key    ${verify_entry}    textContent
        IF    ${has_text}
            ${text_config}=    Get From Dictionary    ${verify_entry}    textContent
            ${expected_text}=    Set Variable    ${text_config}[0]
            ${text_operator}=    Set Variable    ${text_config}[1]
            Verify Text Content    ${xpath}    ${expected_text}    ${text_operator}    ${step_num}
        END

        # Verify tag name if present
        ${has_tag}=    Run Keyword And Return Status
        ...    Dictionary Should Contain Key    ${verify_entry}    tagName
        IF    ${has_tag}
            ${tag_config}=    Get From Dictionary    ${verify_entry}    tagName
            ${expected_tag}=    Set Variable    ${tag_config}[0]
            ${tag_operator}=    Set Variable    ${tag_config}[1]
            Verify Tag Name    ${xpath}    ${expected_tag}    ${tag_operator}    ${step_num}
        END

        # Verify attributes if present
        ${has_attrs}=    Run Keyword And Return Status
        ...    Dictionary Should Contain Key    ${verify_entry}    attributes
        IF    ${has_attrs}
            ${attrs}=    Get From Dictionary    ${verify_entry}    attributes
            Verify Element Attributes    ${xpath}    ${attrs}    ${step_num}
        END
    END

    Log    Step ${step_num}: All verifications passed.
