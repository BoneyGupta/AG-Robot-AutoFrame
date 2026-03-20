*** Settings ***
Library    Collections
Library    String

*** Variables ***
&{BB_LOCAL_VARS}

*** Keywords ***
Initialize Variable Store
    [Documentation]    Initializes the local variable store. Call once at the start of a test run.
    ${store}=    Create Dictionary
    Set Suite Variable    &{BB_LOCAL_VARS}    &{store}

Store Variable
    [Documentation]    Stores a value under the given variable name in the local store.
    [Arguments]    ${name}    ${value}
    Set To Dictionary    ${BB_LOCAL_VARS}    ${name}=${value}
    Set Suite Variable    &{BB_LOCAL_VARS}    &{BB_LOCAL_VARS}
    Log    Stored variable '${name}' = '${value}'

Get Variable
    [Documentation]    Retrieves a stored variable value by name. Fails if not found.
    [Arguments]    ${name}
    ${exists}=    Run Keyword And Return Status    Dictionary Should Contain Key    ${BB_LOCAL_VARS}    ${name}
    IF    not ${exists}
        Fail    Variable '${name}' not found in local store.
    END
    ${value}=    Get From Dictionary    ${BB_LOCAL_VARS}    ${name}
    RETURN    ${value}

Resolve Variable Reference
    [Documentation]    Resolves a {{bb.local.VarName}} reference to its stored value.
    ...                Returns the resolved value string.
    [Arguments]    ${reference}
    ${is_var}=    Run Keyword And Return Status    Should Match Regexp    ${reference}    \\$\\{\\$\\{bb\\.local\\.
    ${stripped}=    Replace String    ${reference}    {{bb.local.    ${EMPTY}
    ${name}=    Replace String    ${stripped}    }}    ${EMPTY}
    ${value}=    Get Variable    ${name}
    RETURN    ${value}

Has Variable Reference
    [Documentation]    Checks if a string contains a {{bb.local.*}} variable reference.
    [Arguments]    ${text}
    ${has_ref}=    Run Keyword And Return Status    Should Match Regexp    ${text}    \\{\\{bb\\.local\\..*?\\}\\}
    RETURN    ${has_ref}

Get All Variables
    [Documentation]    Returns a snapshot (copy) of the full variable store dictionary.
    ${copy}=    Copy Dictionary    ${BB_LOCAL_VARS}    deepcopy=${True}
    RETURN    ${copy}
