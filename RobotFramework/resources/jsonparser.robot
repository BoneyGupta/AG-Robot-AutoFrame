*** Settings ***
Library    OperatingSystem
Library    Collections
Library    String

*** Keywords ***
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
