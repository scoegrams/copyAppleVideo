-- 📸 Bulletproof Camera File Copier for Mac
-- Supports all major camera brands and file formats
-- Created: 2025

-- Camera file extensions by brand
property photoExtensions : {"ARW", "CR2", "CR3", "NEF", "DNG", "RAF", "ORF", "RW2", "PEF", "SRW", "IIQ", "3FR", "FFF", "JPG", "JPEG", "HEIC", "HEIF", "TIF", "TIFF", "PNG"}
property videoExtensions : {"MP4", "MOV", "AVI", "MXF", "XAVC", "AVCHD", "MTS", "M2TS", "MKV", "INSV", "LRV", "THM"}

-- File naming patterns by brand
property sonyPatterns : {"DSC", "IMG", "_DSC"}
property canonPatterns : {"IMG_", "_MG_", "MVI_"}
property nikonPatterns : {"DSC_", "_DSC", "IMG_"}
property fujiPatterns : {"DSCF", "_DSF", "IMG_"}
property olympusPatterns : {"P", "PA", "PB", "PC", "PD", "PE", "PF", "PG", "PH", "PI", "PJ", "PK", "PL", "PM", "PN", "PO", "PP", "PQ", "PR", "PS", "PT", "PU", "PV", "PW", "PX", "PY", "PZ"}
property panasonicPatterns : {"P", "IMG_"}
property pentaxPatterns : {"IMGP", "_IGP"}
property leticaPatterns : {"L", "IMG_"}
property phaseOnePatterns : {"_", "IMG_"}
property hasselbladePatterns : {"_", "IMG_"}
property gopro_djiPatterns : {"GOPR", "GP", "DJI_"}

-- Main execution
try
	-- Welcome dialog
	set welcomeText to "📸 Bulletproof Camera File Copier
	
Supports all major camera brands:
• Sony, Canon, Nikon, Fuji, Olympus
• Panasonic, Pentax, Leica, Phase One
• Hasselblad, GoPro, DJI
• Photos: RAW + JPEG + HEIC
• Videos: MP4, MOV, XAVC, etc.

Choose your copy mode:"
	
	set copyMode to button returned of (display dialog welcomeText buttons {"📋 Copy Specific Files", "📁 Copy All Files", "❌ Cancel"} default button "📁 Copy All Files" with icon note)
	
	if copyMode is "❌ Cancel" then return
	
	-- Get source folder
	set sourceFolder to choose folder with prompt "📁 Select source folder (camera card, import folder, etc.):"
	
	-- Get destination folder
	set destFolder to choose folder with prompt "📁 Select destination folder for copied files:"
	
	-- Initialize counters
	set totalCopied to 0
	set totalErrors to 0
	set errorList to {}
	
	if copyMode is "📋 Copy Specific Files" then
		-- Get file numbers from user
		set fileNumbers to getFileNumbers()
		if fileNumbers is {} then return
		
		-- Copy specific files
		repeat with fileNum in fileNumbers
			set {copied, errors} to copySpecificFile(fileNum, sourceFolder, destFolder)
			set totalCopied to totalCopied + copied
			set totalErrors to totalErrors + (count of errors)
			set errorList to errorList & errors
		end repeat
		
	else
		-- Copy all camera files
		set {totalCopied, errorList} to copyAllCameraFiles(sourceFolder, destFolder)
		set totalErrors to count of errorList
	end if
	
	-- Show completion dialog
	showCompletionDialog(totalCopied, totalErrors, errorList)
	
on error errMsg number errNum
	display dialog "❌ Unexpected Error: " & errMsg & " (Code: " & errNum & ")" buttons {"OK"} default button "OK" with icon stop
end try

-- Function to get file numbers from user
on getFileNumbers()
	set userInput to text returned of (display dialog "Enter file numbers (comma-separated):
	
Examples:
• 05714, 05715, 05717
• 1234, 1235, 1236
• 001, 002, 003

File Numbers:" default answer "" with icon note)
	
	if userInput is "" then return {}
	
	-- Parse comma-separated numbers
	set AppleScript's text item delimiters to ","
	set numberList to text items of userInput
	set AppleScript's text item delimiters to ""
	
	set cleanNumbers to {}
	repeat with num in numberList
		set cleanNum to trimWhitespace(num as string)
		if cleanNum is not "" then
			set end of cleanNumbers to cleanNum
		end if
	end repeat
	
	return cleanNumbers
end getFileNumbers

-- Function to copy specific files by number
on copySpecificFile(fileNumber, sourceFolder, destFolder)
	set copiedCount to 0
	set errorList to {}
	
	-- Try all brand patterns
	set allPatterns to sonyPatterns & canonPatterns & nikonPatterns & fujiPatterns & olympusPatterns & panasonicPatterns & pentaxPatterns & leticaPatterns & phaseOnePatterns & hasselbladePatterns & gopro_djiPatterns
	
	repeat with pattern in allPatterns
		-- Try all extensions
		repeat with ext in (photoExtensions & videoExtensions)
			set fileName to pattern & fileNumber & "." & ext
			set sourcePath to (sourceFolder as string) & fileName
			set destPath to (destFolder as string) & fileName
			
			try
				-- Check if source file exists
				set sourceAlias to sourcePath as alias
				
				-- Copy file with progress
				do shell script "cp " & quoted form of POSIX path of sourcePath & " " & quoted form of POSIX path of destPath
				set copiedCount to copiedCount + 1
				
			on error
				-- File doesn't exist or copy failed - continue silently
			end try
		end repeat
	end repeat
	
	return {copiedCount, errorList}
end copySpecificFile

-- Function to copy all camera files
on copyAllCameraFiles(sourceFolder, destFolder)
	set copiedCount to 0
	set errorList to {}
	
	try
		-- Get all files in source folder
		tell application "Finder"
			set allFiles to every file in folder (sourceFolder as alias)
		end tell
		
		set totalFiles to count of allFiles
		set processedFiles to 0
		
		-- Process each file
		repeat with fileItem in allFiles
			set processedFiles to processedFiles + 1
			
			try
				tell application "Finder"
					set fileName to name of fileItem
					set fileExtension to name extension of fileItem
				end tell
				
				-- Check if it's a camera file
				if isCameraFile(fileName, fileExtension) then
					set sourcePath to (sourceFolder as string) & fileName
					set destPath to (destFolder as string) & fileName
					
					-- Check if destination file already exists
					try
						set destAlias to destPath as alias
						-- File exists, ask user what to do
						set userChoice to button returned of (display dialog "File already exists: " & fileName & "
						
What would you like to do?" buttons {"Skip", "Rename", "Overwrite"} default button "Skip" with icon caution)
						
						if userChoice is "Skip" then
							-- Skip this file
						else if userChoice is "Rename" then
							set destPath to getUniqueFileName(destFolder, fileName)
							do shell script "cp " & quoted form of POSIX path of sourcePath & " " & quoted form of POSIX path of destPath
							set copiedCount to copiedCount + 1
						else if userChoice is "Overwrite" then
							do shell script "cp " & quoted form of POSIX path of sourcePath & " " & quoted form of POSIX path of destPath
							set copiedCount to copiedCount + 1
						end if
					on error
						-- File doesn't exist in destination, safe to copy
						do shell script "cp " & quoted form of POSIX path of sourcePath & " " & quoted form of POSIX path of destPath
						set copiedCount to copiedCount + 1
					end try
				end if
				
				-- Show progress every 10 files
				if processedFiles mod 10 = 0 then
					display notification "Processed " & processedFiles & " of " & totalFiles & " files..." with title "Camera File Copier"
				end if
				
			on error errMsg
				set end of errorList to fileName & ": " & errMsg
			end try
		end repeat
		
	on error errMsg
		set end of errorList to "Folder scan error: " & errMsg
	end try
	
	return {copiedCount, errorList}
end copyAllCameraFiles

-- Function to check if file is a camera file
on isCameraFile(fileName, fileExtension)
	-- Check extension
	set extUpper to toUpperCase(fileExtension)
	if extUpper is in (photoExtensions & videoExtensions) then
		-- Check if filename matches camera patterns
		set fileUpper to toUpperCase(fileName)
		
		-- Check all brand patterns
		set allPatterns to sonyPatterns & canonPatterns & nikonPatterns & fujiPatterns & olympusPatterns & panasonicPatterns & pentaxPatterns & leticaPatterns & phaseOnePatterns & hasselbladePatterns & gopro_djiPatterns
		
		repeat with pattern in allPatterns
			if fileUpper starts with toUpperCase(pattern) then return true
		end repeat
		
		-- Also accept files that start with numbers (some cameras)
		if character 1 of fileName is in {"0", "1", "2", "3", "4", "5", "6", "7", "8", "9"} then return true
	end if
	
	return false
end isCameraFile

-- Function to generate unique filename
on getUniqueFileName(destFolder, originalName)
	set nameWithoutExt to getFileNameWithoutExtension(originalName)
	set fileExt to getFileExtension(originalName)
	set counter to 1
	
	repeat
		set newName to nameWithoutExt & "_" & counter & "." & fileExt
		set testPath to (destFolder as string) & newName
		
		try
			set testAlias to testPath as alias
			set counter to counter + 1
		on error
			return testPath
		end try
	end repeat
end getUniqueFileName

-- Utility functions
on trimWhitespace(str)
	set str to str as string
	repeat while str starts with " " or str starts with tab
		set str to text 2 thru -1 of str
	end repeat
	repeat while str ends with " " or str ends with tab
		set str to text 1 thru -2 of str
	end repeat
	return str
end trimWhitespace

on toUpperCase(str)
	return do shell script "echo " & quoted form of str & " | tr '[:lower:]' '[:upper:]'"
end toUpperCase

on getFileNameWithoutExtension(fileName)
	set AppleScript's text item delimiters to "."
	set nameComponents to text items of fileName
	set AppleScript's text item delimiters to ""
	
	if (count of nameComponents) > 1 then
		set AppleScript's text item delimiters to "."
		set nameWithoutExt to (items 1 thru -2 of nameComponents) as string
		set AppleScript's text item delimiters to ""
		return nameWithoutExt
	else
		return fileName
	end if
end getFileNameWithoutExtension

on getFileExtension(fileName)
	set AppleScript's text item delimiters to "."
	set nameComponents to text items of fileName
	set AppleScript's text item delimiters to ""
	
	if (count of nameComponents) > 1 then
		return item -1 of nameComponents
	else
		return ""
	end if
end getFileExtension

-- Function to show completion dialog
on showCompletionDialog(copiedCount, errorCount, errorList)
	set completionText to "✅ Copy Complete!

📊 Summary:
• Files copied: " & copiedCount & "
• Errors: " & errorCount
	
	if errorCount > 0 then
		set completionText to completionText & "

❌ Errors encountered:
"
		repeat with errorMsg in errorList
			set completionText to completionText & "• " & errorMsg & "
"
		end repeat
	end if
	
	if copiedCount > 0 then
		set completionText to completionText & "

🎉 Your camera files are ready!"
	end if
	
	display dialog completionText buttons {"OK"} default button "OK" with icon note
end showCompletionDialog