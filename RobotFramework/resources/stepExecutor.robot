*** Settings ***
Library    SeleniumLibrary
Library    Collections
Library    String
Library    ../libraries/ScreenshotHelper.py
Resource   variables/paths.robot
Resource   keywords/variableManager.robot
Resource   keywords/wait.robot
Resource   keywords/click.robot
Resource   keywords/input.robot
Resource   keywords/verify.robot
Resource   keywords/calculate.robot

*** Keywords ***
Execute Step
    [Documentation]    Executes a single test step based on its actionType.
    ...                Captures before/during/after screenshots for each step.
    ...                Respects the skip and stopOnFailure flags.
    ...                Returns a result dictionary with status, message, and screenshot paths.
    [Arguments]    ${browser}    ${step_data}

    ${step_number}=    Set Variable    ${step_data}[stepNumber]
    ${action_type}=    Set Variable    ${step_data}[actionType]
    ${section}=        Set Variable    ${step_data}[sectionName]
    ${skip}=           Set Variable    ${step_data}[skip]
    ${stop_on_fail}=   Set Variable    ${step_data}[stopOnFailure]
    ${xpath}=          Set Variable    ${step_data}[xpath]

    # Check if step should be skipped
    IF    '${skip}' == 'Yes'
        Log    Step ${step_number}: SKIPPED [${action_type}] in '${section}'    level=INFO
        ${vars_snapshot}=    Get All Variables
        ${result}=    Create Dictionary
        ...    step=${step_number}    status=SKIP    message=Step skipped
        ...    action=${action_type}    section=${section}
        ...    before=${EMPTY}    during=${EMPTY}    after=${EMPTY}
        ...    variables=${vars_snapshot}
        RETURN    ${result}
    END

    Log    Step ${step_number}: Executing [${action_type}] in '${section}'    level=INFO

    # Capture BEFORE screenshot
    ${before_path}=    Capture Before Screenshot    ${step_number}

    # Capture DURING screenshot (highlight target element)
    ${during_path}=    Capture During Screenshot    ${step_number}    ${xpath}

    # Dispatch to the appropriate action handler
    TRY
        IF    '${action_type}' == 'Click'
            Execute Click    ${step_data}
        ELSE IF    '${action_type}' == 'Type / Input'
            Execute Input    ${step_data}
        ELSE IF    '${action_type}' == 'Verify'
            Execute Verify    ${step_data}
        ELSE IF    '${action_type}' == 'Calculate'
            Execute Calculate    ${step_data}
        ELSE
            Fail    Step ${step_number}: Unknown action type '${action_type}'
        END

        # Capture AFTER screenshot on success
        ${after_path}=    Capture After Screenshot    ${step_number}

        # Capture variable store snapshot
        ${vars_snapshot}=    Get All Variables

        ${result}=    Create Dictionary
        ...    step=${step_number}    status=PASS    message=${action_type} executed successfully
        ...    action=${action_type}    section=${section}
        ...    before=${before_path}    during=${during_path}    after=${after_path}
        ...    variables=${vars_snapshot}
        RETURN    ${result}

    EXCEPT    AS    ${error}
        Log    Step ${step_number} FAILED [${action_type}] in '${section}': ${error}    level=ERROR

        # Capture AFTER screenshot even on failure
        ${after_path}=    Capture After Screenshot    ${step_number}

        # Capture variable store snapshot
        ${vars_snapshot}=    Get All Variables

        IF    '${stop_on_fail}' == 'Yes'
            ${result}=    Create Dictionary
            ...    step=${step_number}    status=FAIL    message=${error}
            ...    action=${action_type}    section=${section}
            ...    before=${before_path}    during=${during_path}    after=${after_path}
            ...    variables=${vars_snapshot}
            # Store result before failing so iterator can catch it
            Fail    STEP_RESULT:${step_number}|${before_path}|${during_path}|${after_path}|${error}
        END

        ${result}=    Create Dictionary
        ...    step=${step_number}    status=FAIL    message=${error}
        ...    action=${action_type}    section=${section}
        ...    before=${before_path}    during=${during_path}    after=${after_path}
        ...    variables=${vars_snapshot}
        RETURN    ${result}
    END
