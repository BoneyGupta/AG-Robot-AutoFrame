*** Settings ***
Library    SeleniumLibrary
Library    String
Resource   jsonparser.robot
Resource   variables/paths.robot

*** Keywords ***
Open Browser From Config
    [Documentation]    Opens a browser based on settings from the JSON config file.
    ...                Supports chrome, edge, and safari. Supports headed/headless mode.
    ...                Returns the browser alias and window handle to the caller.
    [Arguments]    ${json_file_path}

    # Parse the JSON config
    ${json_data}=    Parse JSON Config    ${json_file_path}
    ${browser_name}=    Get Browser Name    ${json_data}
    ${headed}=    Get Headed Mode    ${json_data}
    ${start_page}=    Get Start Page    ${json_data}

    # Detect if startURL is a full URL (http/https) or a local file
    IF    '${start_page}'.startswith('http://') or '${start_page}'.startswith('https://')
        ${start_url}=    Set Variable    ${start_page}
    ELSE
        # Resolve relative path against Website directory
        ${abs_path}=    Evaluate    __import__('os').path.abspath(__import__('os').path.join(r'${WEBSITE_DIR}', r'${start_page}'))
        ${start_url}=    Set Variable    file:///${abs_path}
    END

    # Map config browser name to SeleniumLibrary browser name
    ${browser_lower}=    Convert To Lower Case    ${browser_name}
    ${selenium_browser}=    Set Variable If
    ...    '${browser_lower}' == 'chrome'     chrome
    ...    '${browser_lower}' == 'edge'       edge
    ...    '${browser_lower}' == 'safari'     safari
    ...    NONE

    # Fail if browser type is unsupported
    IF    '${selenium_browser}' == 'NONE'
        Fail    Unsupported browser: ${browser_name}. Supported browsers are chrome, edge, and safari.
    END

    # Detect Docker environment — force headless and no-sandbox
    ${in_docker}=    Evaluate    __import__('os').environ.get('RUNNING_IN_DOCKER', 'false').lower() == 'true'

    # Build browser options based on browser type and headed/headless mode
    ${options}=    Set Variable    ${NONE}
    IF    '${selenium_browser}' == 'chrome' and (${headed} == ${False} or ${in_docker})
        ${options}=    Evaluate    sys.modules['selenium.webdriver'].ChromeOptions()    sys
        Evaluate    $options.add_argument('--headless=new')
        Evaluate    $options.add_argument('--no-sandbox')
        Evaluate    $options.add_argument('--disable-dev-shm-usage')
        Evaluate    $options.add_argument('--disable-gpu')
    ELSE IF    '${selenium_browser}' == 'edge' and (${headed} == ${False} or ${in_docker})
        ${options}=    Evaluate    sys.modules['selenium.webdriver'].EdgeOptions()    sys
        Evaluate    $options.add_argument('--headless=new')
        Evaluate    $options.add_argument('--no-sandbox')
        Evaluate    $options.add_argument('--disable-dev-shm-usage')
        Evaluate    $options.add_argument('--disable-gpu')
    ELSE IF    '${selenium_browser}' == 'safari' and ${headed} == ${False}
        Log    Safari does not support headless mode natively. Opening in headed mode.    level=WARN
    END

    # Open the browser with error handling
    TRY
        IF    $options is not None
            Open Browser    ${start_url}    ${selenium_browser}    options=${options}
        ELSE
            Open Browser    ${start_url}    ${selenium_browser}
        END
        ${window}=    Get Window Handles
        ${current_window}=    Set Variable    ${window}[0]
    EXCEPT    AS    ${error}
        Log    Failed to open browser '${browser_name}': ${error}    level=ERROR
        Fail    Browser launch failed for '${browser_name}' (headed=${headed}): ${error}
    END

    RETURN    ${selenium_browser}    ${current_window}
