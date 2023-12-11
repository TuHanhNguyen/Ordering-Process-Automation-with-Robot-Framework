*** Settings ***
Documentation       Exersive for Lv2 RPA with Robot Framework
...                 Github.com/TuHanhNguyen

Library             RPA.Browser.Playwright
Library             RPA.Excel.Files
Library             RPA.HTTP
Library             OperatingSystem
Library             RPA.Browser.Selenium
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.Archive


*** Variables ***
# ${output_folder}    ${CURDIR}{/}output
${screenshot_folder}        ${OUTPUT_DIR}${/}sceenshots/
${receipt_folder}           ${OUTPUT_DIR}${/}receipts/

${GLOBAL_RETRY_AMOUNT}      10x
${GLOBAL_RETRY_INTERVAL}    2s


*** Tasks ***
Order robots from csv file
    Open ordering website
    ${order_list}=    Get order file and read as table
    FOR    ${row}    IN    @{order_list}
        Close annoying popup
        Fill the form    ${row}
        Wait Until Keyword Succeeds    ${GLOBAL_RETRY_AMOUNT}    ${GLOBAL_RETRY_INTERVAL}    Click button "Preview"
        Wait Until Keyword Succeeds    ${GLOBAL_RETRY_AMOUNT}    ${GLOBAL_RETRY_INTERVAL}    Click button "ORDER"
        ${pdf}=    Store the order receipt as a PDF file
        ${screenshot}=    Take a screenshot of the robot
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Click button "ORDER ANOTHER ROBOT"
    END
    Create a ZIP file of receipt PDF files


*** Keywords ***
Create a ZIP file of receipt PDF files
    Archive Folder With Zip    ${receipt_folder}    receipts.zip    recursive=True
    Move File    receipts.zip    ${receipt_folder}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    Open Pdf    ${pdf}
    @{file_to_add}=    Create List    ${screenshot}:align=center
    Add Files To Pdf    ${file_to_add}    ${pdf}    append=True
    Close Pdf

Store the order receipt as a PDF file
    Set Local Variable    ${receipt_html_locator}    XPATH://html/body/div[1]/div/div[1]/div/div[1]/div/div
    Wait Until Element Is Visible    ${receipt_html_locator}
    ${receipt_html}=    Get Element Attribute    ${receipt_html_locator}    outerHTML
    ${receipt_id}=    RPA.Browser.Selenium.Get Text    XPATH://html/body/div[1]/div/div[1]/div/div[1]/div/div/p[1]
    Html To Pdf
    ...    ${receipt_html}
    ...    ${receipt_folder}${receipt_id}.pdf
    RETURN    ${receipt_folder}${receipt_id}.pdf

Take a screenshot of the robot
    Set Local Variable    ${robot_preview_image_locator}    XPATH://html/body/div[1]/div/div[1]/div/div[2]/div/div
    Set Local Variable    ${robot_image_file_name}    ${order_no}
    Wait Until Element Is Visible    ${robot_preview_image_locator}
    Set Local Variable    ${image_path}    ${screenshot_folder}${robot_image_file_name}
    ${robot_preview_image}=    Screenshot
    ...    ${robot_preview_image_locator}
    ...    ${image_path}.png
    RETURN    ${image_path}.png

# Download robot preview image
#    Set Local Variable    ${robot_preview_image}    XPATH://html/body/div/div/div[1]/div/div[2]/div/div
#    ${robot_preview_image_prefix}=    RPA.Browser.Selenium.Get Value
#    ...    XPATH://html/body/div/div/div[1]/div/div[1]/div/div/div[1]
#    Screenshot    ${robot_preview_image}    filename=${robot_preview_image_prefix}

Click button "Preview"
    Set Local Variable    ${button_preview}    XPATH://html/body/div/div/div[1]/div/div[1]/form/button[1]
    Click Element    ${button_preview}

Click button "ORDER"
    Set Local Variable    ${order_button_locator}    XPATH://html/body/div/div/div[1]/div/div[1]/form/button[2]
    Click Element    ${order_button_locator}
    Page Should Contain Element    XPATH://html/body/div/div/div[1]/div/div[1]/div/button

Click button "ORDER ANOTHER ROBOT"
    Set Local Variable
    ...    ${order_another_robot_button_locator}
    ...    XPATH://html/body/div/div/div[1]/div/div[1]/div/button
    Wait Until Keyword Succeeds
    ...    ${GLOBAL_RETRY_AMOUNT}
    ...    ${GLOBAL_RETRY_INTERVAL}
    ...    Click Element    ${order_another_robot_button_locator}

Open ordering website
    Open Headless Chrome Browser    https://robotsparebinindustries.com/#/robot-order

Close annoying popup
    Set Local Variable    ${annoying_popup_locator}    XPATH://html/body/div/div/div[2]/div/div/div/div/div/button[1]
    Click Element    ${annoying_popup_locator}

Get order file and read as table
    RPA.HTTP.Download    https://robotsparebinindustries.com/orders.csv    overwrite=True
    ${order_list}=    Set Variable    orders.csv
    ${order_list}=    Read table from CSV    ${order_list}
    RETURN    ${order_list}

Fill the form
    [Arguments]    ${order}
    # We need to exact the value from the returned {table}
    # Which is dictinary
    Set Global Variable    ${order_no}    ${order}[Order number]
    Set Local Variable    ${head}    ${order}[Head]
    Set Local Variable    ${body}    ${order}[Body]
    Set Local Variable    ${legs}    ${order}[Legs]
    Set Local Variable    ${shipping_address}    ${order}[Address]

    Select From List By Value    //*[@id="head"]    ${head}
    Select Radio Button    body    ${body}
    Input Text    XPATH://html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${legs}
    Input Text    XPATH://html/body/div/div/div[1]/div/div[1]/form/div[4]/input    ${shipping_address}
    Log    ${order_no}
    RETURN    ${order_no}
