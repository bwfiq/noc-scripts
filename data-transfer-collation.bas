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
    Dim columnC_Name As String

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
        columnC_Name = "Native"

    ElseIf processType = "nextgen" Then
        Set utilSheet = utilWb.Sheets("AllData-Data Transfer NG")
        filterColumn = 4 ' Column D contains websites for NextGen
        tierColumn = 5 ' Column E contains tier for NextGen
        columnC_Name = "NextGen"

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
                    Dim tierValue As String

                    If processType = "native" Then
                        tierValue = newWb.Sheets(1).Cells(i, "D").Value
                        If tierValue = "Large Tier" Or tierValue = "Large HA" Then
                           If IsEmpty(newWb.Sheets(1).Cells(i, "K").Value) Or _
                              IsEmpty(newWb.Sheets(1).Cells(i, "L").Value) Or _
                              IsEmpty(newWb.Sheets(1).Cells(i, "M").Value) Then
                                ' TODO: Split this into multiple outputs with a buffer
                                missingDataWebsites = missingDataWebsites & website & " - missing CDN cache etc" & Chr(13) & Chr(10) 'Add website to the list
                                Exit For 'Break early if we find one row
                            End If
                        End If

                    ElseIf processType = "nextgen" Then
                         tierValue = newWb.Sheets(1).Cells(i, "E").Value
                        If tierValue = "Large" Then
                             If IsEmpty(newWb.Sheets(1).Cells(i, "K").Value) Or _
                                IsEmpty(newWb.Sheets(1).Cells(i, "L").Value) Or _
                                IsEmpty(newWb.Sheets(1).Cells(i, "M").Value) Then

                                  missingDataWebsites = missingDataWebsites & website & Chr(13) & Chr(10) 'Add website to the list
                                  Exit For 'Break early if we find one row
                             End If
                        End If
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
                    saveFileName = columnC_Name & " - Additional Data Transfer - " & website & ".xlsx"
                Else
                    saveFileName = columnC_Name & " - Additional Data Transfer - " & website & " - " & columnCValue & ".xlsx"
                End If


                On Error Resume Next
                Application.DisplayAlerts = False ' Disable alerts for overwriting
                newWb.SaveAs Filename:=saveFileName, FileFormat:=xlOpenXMLWorkbook
                Application.DisplayAlerts = True ' Re-enable alerts
                newWb.Close SaveChanges:=False 'Close without saving changes (avoids prompts)
                If Err.Number <> 0 Then
                    MsgBox "Error saving file: " & Err.Description, vbCritical
                End If
                On Error GoTo 0

                utilSheet.AutoFilterMode = False
            Else
                MsgBox "No data found or invalid Filter Range", vbCritical, "Error"
            End If
        End If
    Next website

    ' ** Create output text file **
    outputFilePath = ThisWorkbook.Path & "\missing-data-report-" & columnC_Name & ".txt" ' Save in the same directory as the Excel file

    If missingDataWebsites <> "" Then ' Only create file if there are websites with missing data

        outputFileNum = FreeFile
        Open outputFilePath For Output As #outputFileNum
        Print #outputFileNum, "Websites with missing data in Columns K, L, or M when Column D is 'Large Tier' or 'Large HA':" & Chr(13) & Chr(10)
        Print #outputFileNum, missingDataWebsites
        Close #outputFileNum

        MsgBox "Done processing the websites.  A report has been generated at " & outputFilePath, vbInformation
    Else
        MsgBox "Done processing the websites. No missing data found for Large Tier/HA sites.", vbInformation
    End If

End Sub

