*** Settings ***
Library    Collections
Library    String
Resource   stepExecutor.robot
Resource   variables/paths.robot

*** Keywords ***
Iterate Steps
    [Documentation]    Iterates through the resolved steps list using a positional index
    ...                for range comparison. stepNumber may be an integer (inline step)
    ...                or a string like "1:3" (page object sub-step).
    ...                Executes steps where position >= start_step AND position < end_step.
    ...                Returns the browser context, count of executed steps, failed steps, and results.
    [Arguments]    ${browser}    ${json_data}    ${start_step}    ${end_step}    ${continue_on_failure}=${True}

    ${steps}=             Set Variable    ${json_data}[steps]
    ${executed_count}=    Set Variable    ${0}
    ${failed_count}=      Set Variable    ${0}
    ${results}=           Create List
    ${position}=          Set Variable    ${1}

    ${start_int}=    Convert To Integer    ${start_step}
    ${end_int}=      Convert To Integer    ${end_step}

    FOR    ${step}    IN    @{steps}
        ${step_number}=    Set Variable    ${step}[stepNumber]

        IF    ${position} >= ${start_int} and ${position} < ${end_int}
            TRY
                ${result}=    Execute Step    ${browser}    ${step}
                ${executed_count}=    Evaluate    ${executed_count} + 1
                Append To List    ${results}    ${result}
            EXCEPT    AS    ${error}
                ${failed_count}=    Evaluate    ${failed_count} + 1
                ${executed_count}=    Evaluate    ${executed_count} + 1

                # Parse screenshot paths from STEP_RESULT encoded failure
                ${is_step_result}=    Run Keyword And Return Status
                ...    Should Start With    ${error}    STEP_RESULT:
                # Capture variable store snapshot at time of failure
                ${vars_snapshot}=    Get All Variables

                IF    ${is_step_result}
                    ${payload}=      Remove String    ${error}    STEP_RESULT:
                    ${parts}=        Split String    ${payload}    |    max_split=4
                    ${s_step}=       Set Variable    ${parts}[0]
                    ${s_before}=     Set Variable    ${parts}[1]
                    ${s_during}=     Set Variable    ${parts}[2]
                    ${s_after}=      Set Variable    ${parts}[3]
                    ${s_msg}=        Set Variable    ${parts}[4]
                    ${fail_result}=    Create Dictionary
                    ...    step=${s_step}    status=FAIL    message=${s_msg}
                    ...    action=${step}[actionType]    section=${step}[sectionName]
                    ...    before=${s_before}    during=${s_during}    after=${s_after}
                    ...    variables=${vars_snapshot}
                ELSE
                    ${action}=    Set Variable    ${step}[actionType]
                    ${section}=   Set Variable    ${step}[sectionName]
                    Log    Step ${step_number} FAILED [${action}] in '${section}': ${error}    level=ERROR
                    ${fail_result}=    Create Dictionary
                    ...    step=${step_number}    status=FAIL    message=${error}
                    ...    action=${action}    section=${section}
                    ...    before=${EMPTY}    during=${EMPTY}    after=${EMPTY}
                    ...    variables=${vars_snapshot}
                END
                Append To List    ${results}    ${fail_result}
                # Stop execution if this step had stopOnFailure=Yes (STEP_RESULT encoded)
                # or if continue_on_failure is disabled
                IF    ${is_step_result}
                    Log    Step ${step_number}: stopOnFailure is Yes — halting execution.    level=ERROR
                    BREAK
                END
                IF    not ${continue_on_failure}
                    Fail    Step ${step_number} failed and continue_on_failure is disabled: ${error}
                END
            END
        END
        ${position}=    Evaluate    ${position} + 1
    END

    Log    Step iteration complete: ${executed_count} executed, ${failed_count} failed (range ${start_step} to ${end_step})    level=INFO
    RETURN    ${browser}    ${executed_count}    ${failed_count}    ${results}
