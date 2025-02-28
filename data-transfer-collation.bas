Sub ProcessWebsitesFromTextFile()

    Dim utilWb As Workbook, utilSheet As Worksheet
    Dim websiteList As Variant, website As Variant
    Dim saveFileName As String
    Dim filterRange As Range
    Dim ws As Worksheet
    Dim filePath As String, fileContent As String, fileNum As Integer
    Dim newWb As Workbook
    Dim lastRow As Long
    Dim i As Long
    Dim missingDataWebsites As String
    Dim outputFilePath As String, outputFileNum As Integer
    Dim processType As String ' "Native" or "NextGen"
    Dim filterColumn As Long ' Column to filter website from source data (Native=3, NextGen=4)
    Dim tierColumn As Long    ' Column to get tier data (Native=4, NextGen=5)
    Dim websiteType As String
    
    ' Tell Excel not to Update the screen
    Application.ScreenUpdating = False

    ' ** Input Box to Choose Native or NextGen **
    processType = InputBox("Enter 'Native' or 'NextGen':", "Select Process Type", "Native")
    processType = LCase(Trim(processType)) 'convert user input to lowercase and trim it for easy comparison

    ' ** Validate user input **
    If processType <> "native" And processType <> "nextgen" Then
        MsgBox "Invalid Process Type. Please enter 'Native' or 'NextGen'.", vbCritical
        Exit Sub
    End If


    Set utilWb = ThisWorkbook

    ' TODO: Handle both in one

    If processType = "native" Then
        Set utilSheet = utilWb.Sheets("AllData-Data Transfer")
        filterColumn = 3 ' Column C contains websites for Native
        tierColumn = 4 ' Column D contains tier for Native
        websiteType = "Native"

    ElseIf processType = "nextgen" Then
        Set utilSheet = utilWb.Sheets("AllData-Data Transfer NG")
        filterColumn = 4 ' Column D contains websites for NextGen
        tierColumn = 5 ' Column E contains tier for NextGen
        websiteType = "NextGen"

    End If

    missingDataWebsites = "" ' Initialize empty string

    ' ** 1. Get the file path using Application.GetOpenFilename
    filePath = Application.GetOpenFilename(FileFilter:="Text Files (*.txt), *.txt", Title:="Select Text File with Website List")

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

    ' ** 4. Process each website
    For Each website In websiteList
        website = Trim(website)

        If website <> "" Then
            On Error Resume Next
            utilSheet.AutoFilterMode = False
            On Error GoTo 0

            ' Determine last row based on the Domain column
            lastRow = utilSheet.Cells(Rows.Count, "A").End(xlUp).Row
            Set filterRange = utilSheet.Range("A1:Z" & lastRow)

            If Not filterRange Is Nothing Then
                filterRange.AutoFilter Field:=filterColumn, Criteria1:=website

                'Create a new workbook
                Set newWb = Workbooks.Add

                'Copy filtered data to the new workbook
                filterRange.SpecialCells(xlCellTypeVisible).Copy newWb.Sheets(1).Range("A1")

                'Autofit columns and rows
                With newWb.Sheets(1)
                    .Columns.AutoFit
                    .Rows.AutoFit
                End With

                ' ** Data Validation Loop **
                ' Here we check if any data is missing that should be included in the final output
                Dim sourceLastRow As Long
                sourceLastRow = newWb.Sheets(1).Cells(Rows.Count, "A").End(xlUp).Row

                For i = 2 To sourceLastRow 'Start at row 2 to skip headers
                    Dim missingColumns As String ' Buffer to store the missing column names

                    missingColumns = "" ' Initialize the buffer
                    
                    ' Check if Project Code value is available
                    If IsEmpty(newWb.Sheets(1).Cells(i, "C").Value) Then
                        missingColumns = missingColumns & "Project Code, "
                    End If
                    
                    ' Tier Checking
                    Dim tierValue As String
                    Dim tierCheck As Boolean ' Flag to determine if the tier condition is met

                    ' Determine tier value and check based on process type
                    If processType = "native" Then
                        tierValue = newWb.Sheets(1).Cells(i, "D").Value ' Tier column for native
                        tierCheck = (tierValue = "Large Tier" Or tierValue = "Large HA")  ' Parenthesis used to create readability
                    ElseIf processType = "nextgen" Then
                        tierValue = newWb.Sheets(1).Cells(i, "E").Value ' Tier column for nextgen
                        tierCheck = (tierValue = "Large") ' Parenthesis used to create readability
                    End If

                    ' Check if the tier condition is met AND if K, L, or M are empty
                    If tierCheck Then                        
                        ' Check if CDN Cache value is available
                        If IsEmpty(newWb.Sheets(1).Cells(i, "K").Value) Then
                            missingColumns = missingColumns & "K, "
                        End If

                        ' Check if HA value is there
                        If IsEmpty(newWb.Sheets(1).Cells(i, "L").Value) Then
                            missingColumns = missingColumns & "L, "
                        End If

                        ' Check if Eligible for Discount value is there
                        If IsEmpty(newWb.Sheets(1).Cells(i, "M").Value) Then
                            missingColumns = missingColumns & "M, "
                        End If
                    End If
                    

                    ' Check if any columns were missing
                    If missingColumns <> "" Then
                        ' Remove the trailing comma and space
                        missingColumns = Left(missingColumns, Len(missingColumns) - 2)

                        missingDataWebsites = missingDataWebsites & "Row " & i & ": " & website & " (Missing data: " & missingColumns & ")" & Chr(13) & Chr(10) ' Add website and missing columns to the list
                        'Exit For ' Break early if we find one row with missing data
                    End If
                Next i

                ' ** Clean up **
                ' In this section, we will clean up the data for the agencies
                
                ' TODO: Change the Jira Ticket Links
                
                ' ** Delete Columns **
                ' Make sure to delete RIGHT TO LEFT so columns won't shift
                ' A is the recording date
                ' N is either Has Subsite or Action
                ' O is Total Base with Subsite
                ' P is Remark
                With newWb.Sheets(1)
                    .Columns("P").Delete
                    .Columns("O").Delete
                    .Columns("N").Delete
                    .Columns("A").Delete
                End With

                ' ** MODIFIED SAVE FILE NAME **
                'Get the value from column C of the FIRST visible row (after the header) in the filtered range
                ' TODO: If columnC is empty, make it output a error message so I can manually fix it.
                Dim columnCValue As String
                On Error Resume Next 'In case no visible rows exist after filter
                columnCValue = utilSheet.Range("C2:C" & lastRow).SpecialCells(xlCellTypeVisible)(1, 1).Value
                On Error GoTo 0

                If columnCValue = "" Then
                    saveFileName = websiteType & " - Additional Data Transfer - " & website & ".xlsx"
                Else
                    saveFileName = websiteType & " - Additional Data Transfer - " & website & " - " & columnCValue & ".xlsx"
                End If


                On Error Resume Next
                Application.DisplayAlerts = False ' Disable alerts for overwriting
                newWb.SaveAs Filename:=saveFileName, FileFormat:=xlOpenXMLWorkbook
                Application.DisplayAlerts = True ' Re-enable alerts
                newWb.Close SaveChanges:=False 'Close without saving changes (avoids prompts)
                If Err.Number <> 0 Then
                    MsgBox "Error saving file (" & saveFileName & "): " & Err.Description, vbCritical
                End If
                On Error GoTo 0

                utilSheet.AutoFilterMode = False
            Else
                MsgBox "No data found or invalid Filter Range", vbCritical, "Error"
            End If
        End If
    Next website

    ' ** Create output text file **
    outputFilePath = ThisWorkbook.Path & "\missing-data-report-" & websiteType & ".txt" ' Save in the same directory as the Excel file

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