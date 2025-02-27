Attribute VB_Name = "Module1"
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

    Set utilWb = ThisWorkbook
    Set utilSheet = utilWb.Sheets("AllData-Data Transfer NG")
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

            lastRow = utilSheet.Cells(Rows.Count, "D").End(xlUp).Row

            Set filterRange = utilSheet.Range("A1:Z" & lastRow)
            If Not filterRange Is Nothing Then
                'Check Row D
                filterRange.AutoFilter Field:=4, Criteria1:=website

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
                Dim sourceLastRow As Long
                sourceLastRow = newWb.Sheets(1).Cells(Rows.Count, "A").End(xlUp).Row

                For i = 2 To sourceLastRow 'Start at row 2 to skip headers

                    If newWb.Sheets(1).Cells(i, "E").Value = "Large" Then
                        If IsEmpty(newWb.Sheets(1).Cells(i, "K").Value) Or _
                           IsEmpty(newWb.Sheets(1).Cells(i, "L").Value) Or _
                           IsEmpty(newWb.Sheets(1).Cells(i, "M").Value) Then

                            missingDataWebsites = missingDataWebsites & website & Chr(13) & Chr(10) 'Add website and row to the list
                            Exit For 'Break early if we find one row
                        End If
                    End If
                Next i
                
                ' ** MODIFIED SAVE FILE NAME **
                'Get the value from column C of the FIRST visible row (after the header) in the filtered range
                Dim columnCValue As String
                On Error Resume Next 'In case no visible rows exist after filter
                columnCValue = utilSheet.Range("C2:C" & lastRow).SpecialCells(xlCellTypeVisible)(1, 1).Value
                On Error GoTo 0

                If columnCValue = "" Then
                    saveFileName = "NextGen - Additional Data Transfer - " & website & ".xlsx"
                Else
                    saveFileName = "NextGen - Additional Data Transfer - " & website & " - " & columnCValue & ".xlsx"
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
    outputFilePath = ThisWorkbook.Path & "\missing-data-report-nextgen.txt" ' Save in the same directory as the Excel file

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




