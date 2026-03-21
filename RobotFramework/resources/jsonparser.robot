*** Settings ***
Library    OperatingSystem
Library    Collections
Library    String
Resource   variables/paths.robot

*** Keywords ***
Resolve Page Objects
    [Documentation]    Resolves the steps array from the config into a flat list of executable steps.
    ...                Iterates through each step in json_data[steps]:
    ...                - If actionType is 'PageObject', loads the referenced file and expands
    ...                  its steps inline (respecting the skip flag on the PageObject step).
    ...                - Otherwise, keeps the step as-is.
    ...                All steps are renumbered globally starting from 1.
    [Arguments]    ${json_data}

    ${steps}=          Set Variable    ${json_data}[steps]
    ${all_steps}=      Create List
    ${global_step}=    Set Variable    ${1}

    FOR    ${step}    IN    @{steps}
        ${action}=    Set Variable    ${step}[actionType]

        IF    '${action}' == 'PageObject'
            # Check if this page object reference should be skipped
            ${po_skip}=    Set Variable    ${step}[skip]
            ${po_ref}=     Set Variable    ${step}[ref]

            IF    '${po_skip}' == 'Yes'
                Log    PageObject '${po_ref}' skipped.    level=INFO
                ${global_step}=    Evaluate    ${global_step} + 1
            ELSE
                ${po_file}=    Set Variable    ${PAGE_OBJECTS_DIR}${/}${po_ref}
                ${po_data}=    Parse JSON Config    ${po_file}
                ${po_steps}=   Set Variable    ${po_data}[steps]
                ${parent_step}=    Set Variable    ${global_step}
                ${sub_step}=       Set Variable    ${1}

                FOR    ${po_step}    IN    @{po_steps}
                    ${step_label}=    Set Variable    ${parent_step}:${sub_step}
                    Set To Dictionary    ${po_step}    stepNumber    ${step_label}
                    Append To List    ${all_steps}    ${po_step}
                    ${sub_step}=    Evaluate    ${sub_step} + 1
                END
                ${global_step}=    Evaluate    ${global_step} + 1
            END
        ELSE
            # Regular inline step — renumber and keep
            Set To Dictionary    ${step}    stepNumber    ${global_step}
            Append To List    ${all_steps}    ${step}
            ${global_step}=    Evaluate    ${global_step} + 1
        END
    END

    RETURN    ${all_steps}

Parse JSON Config
    [Documentation]    Reads and parses the output.json config file. Returns the parsed JSON as a dictionary.
    [Arguments]    ${json_file_path}
    ${file_content}=    Get File    ${json_file_path}    encoding=UTF-8
    ${json_data}=    Evaluate    json.load(open(r'${json_file_path}', encoding='utf-8'))    json
    RETURN    ${json_data}

Get Browser Name
    [Documentation]    Extracts the browser name from the parsed JSON config.
    [Arguments]    ${json_data}
    ${browser}=    Set Variable    ${json_data}[browser]
    RETURN    ${browser}

Get Headed Mode
    [Documentation]    Extracts the headed mode flag from the parsed JSON config.
    [Arguments]    ${json_data}
    ${headed}=    Set Variable    ${json_data}[headed]
    RETURN    ${headed}

Get Start Page
    [Documentation]    Extracts the start page filename from the parsed JSON config.
    [Arguments]    ${json_data}
    ${start_page}=    Set Variable    ${json_data}[startURL]
    RETURN    ${start_page}
