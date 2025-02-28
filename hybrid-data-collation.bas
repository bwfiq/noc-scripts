Sub ProcessWebsitesFromTextFileCombined()

    Dim utilWb As Workbook
    Dim websiteList As Variant, websiteElement As Variant, singleWebsite As Variant
    Dim saveFileName As String
    Dim filePath As String, fileContent As String, fileNum As Integer
    Dim newWb As Workbook
    Dim missingDataWebsites As String
    Dim outputFilePath As String, outputFileNum As Integer
    Dim subfolderPath As String
    Dim combinedWb As Workbook, combinedSheet As Worksheet

    ' Tell Excel not to Update the screen
    Application.ScreenUpdating = False

    Set utilWb = ThisWorkbook

    ' ** 1. Get the file path using Application.GetOpenFilename
    filePath = Application.GetOpenFilename(FileFilter:="Text Files (*.txt), *.txt", Title:="Select Text File with Combined Website List")

    ' Check if the user cancelled
    If filePath = "False" Then ' User pressed Cancel
        MsgBox "File selection cancelled.", vbInformation
        Exit Sub
    End If

    ' ** 2. Read the file content
    fileNum = FreeFile ' Get the next available file number
    Open filePath For Input As #fileNum
    fileContent = Input(LOF(fileNum), fileNum) ' Read entire file into fileContent
    Close #fileNum

    ' ** 3. Split the file content into a website list
    websiteList = Split(fileContent, ",")

    ' ** 4. Process each website and save it to file

    subfolderPath = ThisWorkbook.Path & "\OutputFiles" ' Name of the subfolder

    ' Check if the subfolder exists. If not, create it.
    If Dir(subfolderPath, vbDirectory) = "" Then
        MkDir subfolderPath ' Creates the subfolder
    End If

    missingDataWebsites = "" ' Initialize empty string


    ' Loop through all the specified websites
    For Each websiteElement In websiteList
        websiteElement = Trim(websiteElement)
        Dim nativeWebsite As String, nextgenWebsite As String
        Dim websites() As String

        ' Split the website element into two websites if a slash exists
        websites = Split(websiteElement, "/")

        If UBound(websites) = 0 Then ' Only one website
            nativeWebsite = Trim(websites(0))
            nextgenWebsite = Trim(websites(0))
        ElseIf UBound(websites) = 1 Then ' Two websites
            nativeWebsite = Trim(websites(0))
            nextgenWebsite = Trim(websites(1))
        Else
            MsgBox "Invalid website format: " & websiteElement, vbCritical
            GoTo NextWebsite
        End If

        ' Create a new workbook to combine the results
        Set combinedWb = Workbooks.Add
        Set combinedSheet = combinedWb.Sheets(1)

        ' Process the Native website
        If nativeWebsite <> "" Then
            Call ProcessWebsite(utilWb, combinedSheet, nativeWebsite, "Native")
        End If

        ' Process the NextGen website
        If nextgenWebsite <> "" Then
            Call ProcessWebsite(utilWb, combinedSheet, nextgenWebsite, "NextGen")
        End If

        ' ** If any data was added, then do data validation, cleanup, formatting and saving **
        If combinedSheet.UsedRange.Rows.Count > 1 Then 'Only process if data was copied

            Dim projectCode As String
            'Find project code from nextgen website process
            If Not IsEmpty(nextgenWebsite) Then
                projectCode = GetProjectCode(utilWb, nextgenWebsite)
            Else
                projectCode = ""
            End If

            ' ** Data Validation Loop **
            ' Here we check if any data is missing that should be included in the final output
            Dim sourceLastRow As Long, i As Long
            sourceLastRow = combinedSheet.Cells(Rows.Count, "A").End(xlUp).Row

            For i = 2 To sourceLastRow 'Start at row 2 to skip headers
                Dim missingColumns As String ' Buffer to store the missing column names

                missingColumns = "" ' Initialize the buffer

                ' Check if Project Code value is available
                If IsEmpty(combinedSheet.Cells(i, "C").Value) Then
                    missingColumns = missingColumns & "Project Code, "
                End If

                ' Tier Checking
                Dim tierValue As String
                Dim tierCheck As Boolean ' Flag to determine if the tier condition is met

                ' Determine tier value and check based on process type
                'Since this is a combination of both, we assume it will use the nextgen process
                tierValue = combinedSheet.Cells(i, "E").Value ' Tier column for nextgen
                tierCheck = (tierValue = "Large") ' Parenthesis used to create readability


                ' Check if the tier condition is met AND if K, L, or M are empty
                If tierCheck Then
                    ' Check if CDN Cache value is available
                    If IsEmpty(combinedSheet.Cells(i, "K").Value) Then
                        missingColumns = missingColumns & "K, "
                    End If

                    ' Check if HA value is there
                    If IsEmpty(combinedSheet.Cells(i, "L").Value) Then
                        missingColumns = missingColumns & "L, "
                    End If

                    ' Check if Eligible for Discount value is there
                    If IsEmpty(combinedSheet.Cells(i, "M").Value) Then
                        missingColumns = missingColumns & "M, "
                    End If
                End If


                ' Check if any columns were missing
                If missingColumns <> "" Then
                    ' Remove the trailing comma and space
                    missingColumns = Left(missingColumns, Len(missingColumns) - 2)

                    missingDataWebsites = missingDataWebsites & websiteElement & " (Missing data: " & missingColumns & ")" & Chr(13) & Chr(10) ' Add website and missing columns to the list
                    Exit For ' Break early if we find one row with missing data
                End If
            Next i


            ' ** Clean up **
            ' In this section, we will clean up the data for the agencies

            ' ** Jira Ticket Link Update **
            ' Loop through each row in the new workbook and modify the Jira links
            Dim jiraLastRow As Long, j As Long
            jiraLastRow = combinedSheet.Cells(Rows.Count, "A").End(xlUp).Row ' Or use column Q if column A might have blank cells

            For j = 2 To jiraLastRow ' Skip header row
                Dim jiraLink As String, extractedValue As String

                ' ** Remove Hyperlinks from Column Q **
                If combinedSheet.Cells(j, "Q").Hyperlinks.Count > 0 Then
                    combinedSheet.Cells(j, "Q").Hyperlinks.Delete
                End If

                jiraLink = combinedSheet.Cells(j, "Q").Value ' Get value from column Q

                ' Check if the cell is not empty and is a valid URL
                If Not IsEmpty(jiraLink) And InStr(1, jiraLink, "https://jira.cwp2.cloudvanti.com/browse/") > 0 Then

                    ' Extract the "$SOMETHING" portion
                    extractedValue = Mid(jiraLink, InStrRev(jiraLink, "/") + 1)

                    ' Construct the new Jira link
                    combinedSheet.Cells(j, "Q").Value = "https://jira.cwp2.cloudvanti.com/servicedesk/customer/portal/1/" & extractedValue
                End If
            Next j


            ' ** Delete Columns **
            ' Make sure to delete RIGHT TO LEFT so columns won't shift
            ' A is the recording date
            ' N is either Has Subsite or Action
            ' O is Total Base with Subsite
            ' P is Remark
            With combinedSheet
                .Columns("P").Delete
                .Columns("O").Delete
                .Columns("N").Delete
                .Columns("A").Delete
            End With

            ' ** FORMATTING **
            With combinedSheet.Range("A1:M" & combinedSheet.UsedRange.Rows.Count) ' Limit to columns A:M
                ' ** All Cells Formatting **
                .Cells.Interior.Color = RGB(255, 255, 255) ' White
                .Cells.Font.Color = RGB(0, 0, 0) ' Black
                .Cells.Font.Name = "Calibri"
                .Cells.Font.Size = 12
                .VerticalAlignment = xlCenter
                .HorizontalAlignment = xlCenter
                .Borders.LineStyle = xlContinuous
                .Borders.Weight = xlThin
            End With

            ' ** Header Row Formatting **
            With combinedSheet.Range("A1:M1") ' Limit to columns A:M in the first row
                .Interior.Color = RGB(0, 148, 200)  ' Light Blue:  Could use a different shade of blue if desired.
                .Font.Color = RGB(255, 255, 255) ' White
            End With

            'Autofit columns and rows
            With combinedSheet
                .Columns.AutoFit
                .Rows.AutoFit
            End With


            saveFileName = subfolderPath & "\Native and NextGen - Additional Data Transfer - " & Replace(websiteElement, "/", " & ") & " - " & projectCode & ".xlsx"

            On Error Resume Next
            Application.DisplayAlerts = False ' Disable alerts for overwriting
            combinedWb.SaveAs Filename:=saveFileName, FileFormat:=xlOpenXMLWorkbook
            Application.DisplayAlerts = True ' Re-enable alerts
            combinedWb.Close SaveChanges:=False 'Close without saving changes (avoids prompts)
            If Err.Number <> 0 Then
                MsgBox "Error saving file (" & saveFileName & "): " & Err.Description, vbCritical
            End If
            On Error GoTo 0
        Else
            combinedWb.Close SaveChanges:=False 'Close without saving changes (avoids prompts)
        End If ' End If combinedSheet.UsedRange.Rows.Count > 1

NextWebsite:
    Next websiteElement

    ' ** Create output text file **
    outputFilePath = ThisWorkbook.Path & "\missing-data-report-combined.txt" ' Save in the same directory as the Excel file

    If missingDataWebsites <> "" Then ' Only create file if there are websites with missing data

        outputFileNum = FreeFile
        Open outputFilePath For Output As #outputFileNum
        Print #outputFileNum, "Websites with missing data:" & Chr(13) & Chr(10)
        Print #outputFileNum, missingDataWebsites
        Close #outputFileNum

        MsgBox "Done processing the websites.  A report has been generated at " & outputFilePath, vbInformation
    Else
        MsgBox "Done processing the websites. No missing data found.", vbInformation
    End If

    ' Tell Excel to continue updating the screen to show the user the result
    Application.ScreenUpdating = True

End Sub

'Helper function to process the website for a given type and append data
Sub ProcessWebsite(utilWb As Workbook, combinedSheet As Worksheet, website As String, websiteType As String)
    Dim utilSheet As Worksheet
    Dim filterColumn As Long
    Dim lastRow As Long
    Dim filterRange As Range
    Dim copyRange As Range
    Dim destRow As Long
    Dim rowsFound As Boolean

    If websiteType = "Native" Then
        Set utilSheet = utilWb.Sheets("AllData-Data Transfer")
        filterColumn = 3 ' Column C contains websites for Native
    ElseIf websiteType = "NextGen" Then
        Set utilSheet = utilWb.Sheets("AllData-Data Transfer NG")
        filterColumn = 4 ' Column D contains websites for NextGen
    Else
        MsgBox "Invalid website type: " & websiteType, vbCritical
        Exit Sub
    End If

    On Error Resume Next
    utilSheet.AutoFilterMode = False
    On Error GoTo 0

    lastRow = utilSheet.Cells(Rows.Count, "A").End(xlUp).Row
    Set filterRange = utilSheet.Range("A1:Z" & lastRow)

    If Not filterRange Is Nothing Then
        filterRange.AutoFilter Field:=filterColumn, Criteria1:=website

        ' ** CHECK IF ANY ROWS WERE FOUND **
        If utilSheet.Range("A1:A" & lastRow).SpecialCells(xlCellTypeVisible).Count > 1 Then
            rowsFound = True ' Set rowsFound flag to True if rows were found
        Else
            rowsFound = False ' No rows were found
        End If


        If rowsFound Then
            Set copyRange = filterRange.SpecialCells(xlCellTypeVisible)

            ' Determine the next available row in the combined sheet
            destRow = combinedSheet.Cells(Rows.Count, "A").End(xlUp).Row + 1
            If destRow = 2 Then destRow = 1 'If there is no header copy to row 1

            ' Copy the filtered data to the combined sheet
            copyRange.Copy combinedSheet.Cells(destRow, 1)

        End If
        utilSheet.AutoFilterMode = False

    Else
        MsgBox "No data found or invalid Filter Range", vbCritical, "Error"
    End If

End Sub

Function GetProjectCode(utilWb As Workbook, website As String) As String
    Dim utilSheet As Worksheet
    Dim filterColumn As Long
    Dim lastRow As Long
    Dim filterRange As Range
    Dim projectCode As String
    Dim rowsFound As Boolean

    Set utilSheet = utilWb.Sheets("AllData-Data Transfer NG")
    filterColumn = 4 ' Column D contains websites for NextGen

    On Error Resume Next
    utilSheet.AutoFilterMode = False
    On Error GoTo 0

    lastRow = utilSheet.Cells(Rows.Count, "A").End(xlUp).Row
    Set filterRange = utilSheet.Range("A1:Z" & lastRow)

    If Not filterRange Is Nothing Then
        filterRange.AutoFilter Field:=filterColumn, Criteria1:=website

        ' ** CHECK IF ANY ROWS WERE FOUND **
        If utilSheet.Range("A1:A" & lastRow).SpecialCells(xlCellTypeVisible).Count > 1 Then
            rowsFound = True ' Set rowsFound flag to True if rows were found
        Else
            rowsFound = False ' No rows were found
        End If

        If rowsFound Then
            'Get the value from column C of the FIRST visible row (after the header) in the filtered range
            On Error Resume Next 'In case no visible rows exist after filter
            projectCode = utilSheet.Range("C2:C" & lastRow).SpecialCells(xlCellTypeVisible)(1, 1).Value
            On Error GoTo 0
            GetProjectCode = projectCode
        Else
            GetProjectCode = ""
        End If

        utilSheet.AutoFilterMode = False

    Else
        MsgBox "No data found or invalid Filter Range", vbCritical, "Error"
    End If
End Function
