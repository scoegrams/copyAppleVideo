-- 📸 Smart Camera File Copier for Mac
-- Intelligent file number matching and fast processing
-- Created: 2025 by scoegrams

-- Camera file extensions by brand
property photoExtensions : {"ARW", "CR2", "CR3", "NEF", "DNG", "RAF", "ORF", "RW2", "PEF", "SRW", "IIQ", "3FR", "FFF", "JPG", "JPEG", "HEIC", "HEIF", "TIF", "TIFF", "PNG"}
property videoExtensions : {"MP4", "MOV", "AVI", "MXF", "XAVC", "AVCHD", "MTS", "M2TS", "MKV", "INSV", "LRV", "THM"}

-- Main execution
try
	-- Simple and fast welcome dialog
	set welcomeText to "📸 Camera File Copier
	
Choose your copy mode:"
	
	set copyMode to button returned of (display dialog welcomeText buttons {"🎯 Smart Select", "📁 Copy All", "❌ Cancel"} default button "🎯 Smart Select" with icon note)
	
	if copyMode is "❌ Cancel" then return
	
	-- Get source folder
	set sourceFolder to choose folder with prompt "📁 Select source folder:"
	
	-- Get destination folder
	set destFolder to choose folder with prompt "📁 Select destination folder:"
	
	-- Initialize counters
	set totalCopied to 0
	set totalErrors to 0
	set errorList to {}
	
	if copyMode is "🎯 Smart Select" then
		-- Smart select interface
		set {totalCopied, errorList} to smartSelectInterface(sourceFolder, destFolder)
		set totalErrors to count of errorList
	else
		-- Copy all camera files
		set {totalCopied, errorList} to copyAllCameraFiles(sourceFolder, destFolder)
		set totalErrors to count of errorList
	end if
	
	-- Show completion dialog
	showCompletionDialog(totalCopied, totalErrors, errorList)
	
on error errMsg number errNum
	display dialog "❌ Error: " & errMsg buttons {"OK"} default button "OK" with icon stop
end try

-- NEW: Simple and fast smart select interface
on smartSelectInterface(sourceFolder, destFolder)
	set copiedCount to 0
	set errorList to {}
	
	-- Scan files quickly
	set {cameraFiles, fileIndex} to scanAndIndexFiles(sourceFolder)
	
	if cameraFiles is {} then
		display dialog "No camera files found." buttons {"OK"} default button "OK" with icon caution
		return {0, {"No camera files found"}}
	end if
	
	-- Simple selection interface
	set selectedFiles to simpleFileSelector(cameraFiles)
	
	if selectedFiles is {} then
		return {0, {}}
	end if
	
	-- Quick confirmation
	set confirmText to "Copy " & (count of selectedFiles) & " files?"
	set proceedChoice to button returned of (display dialog confirmText buttons {"Copy", "Cancel"} default button "Copy" with icon note)
	
	if proceedChoice is "Copy" then
		repeat with fileName in selectedFiles
			set {copied, errors} to copySingleFile(fileName, sourceFolder, destFolder)
			set copiedCount to copiedCount + copied
			set errorList to errorList & errors
		end repeat
	end if
	
	return {copiedCount, errorList}
end smartSelectInterface

-- NEW: Simple file selector
on simpleFileSelector(cameraFiles)
	set selectedFiles to {}
	
	-- Group files quickly
	set groupedFiles to groupFilesByNumber(cameraFiles)
	
	-- Simple selection options
	set selectionText to "Found " & (count of cameraFiles) & " files in " & (count of groupedFiles) & " groups.
	
Select files to copy:"
	
	set selectionChoice to button returned of (display dialog selectionText buttons {"📸 Photos Only", "🎥 Videos Only", "📸🎥 All Files", "❌ Cancel"} default button "📸🎥 All Files" with icon note)
	
	if selectionChoice is "Cancel" then return {}
	
	if selectionChoice is "📸 Photos Only" then
		-- Select only photos
		repeat with fileName in cameraFiles
			if isPhotoFile(fileName) then
				set end of selectedFiles to fileName
			end if
		end repeat
		
	else if selectionChoice is "🎥 Videos Only" then
		-- Select only videos
		repeat with fileName in cameraFiles
			if isVideoFile(fileName) then
				set end of selectedFiles to fileName
			end if
		end repeat
		
	else if selectionChoice is "📸🎥 All Files" then
		-- Select all files
		set selectedFiles to cameraFiles
	end if
	
	return selectedFiles
end simpleFileSelector

-- NEW: Check if file is a photo
on isPhotoFile(fileName)
	set fileExt to getFileExtension(fileName)
	set extUpper to toUpperCase(fileExt)
	return extUpper is in photoExtensions
end isPhotoFile

-- NEW: Check if file is a video
on isVideoFile(fileName)
	set fileExt to getFileExtension(fileName)
	set extUpper to toUpperCase(fileExt)
	return extUpper is in videoExtensions
end isVideoFile

-- NEW: Group files by their number
on groupFilesByNumber(cameraFiles)
	set groupedFiles to {}
	set numberGroups to {}
	
	repeat with fileName in cameraFiles
		set fileNumber to extractNumberFromFileName(fileName)
		if fileNumber is not "" then
			-- Check if we already have this number group
			set foundGroup to false
			repeat with i from 1 to (count of numberGroups)
				set existingGroup to item i of numberGroups
				if item 1 of existingGroup is fileNumber then
					-- Add file to existing group
					set existingFiles to item 2 of existingGroup
					set end of existingFiles to fileName
					set item 2 of existingGroup to existingFiles
					set foundGroup to true
					exit repeat
				end if
			end repeat
			
			if not foundGroup then
				-- Create new group
				set newGroup to {fileNumber, {fileName}}
				set end of numberGroups to newGroup
			end if
		end if
	end repeat
	
	return numberGroups
end groupFilesByNumber

-- NEW: Sort groups by number
on sortGroupsByNumber(fileGroups)
	set sortedGroups to {}
	
	repeat with groupInfo in fileGroups
		set groupNumber to item 1 of groupInfo
		set groupFiles to item 2 of groupInfo
		
		-- Insert in sorted position
		set inserted to false
		repeat with i from 1 to (count of sortedGroups)
			set existingGroup to item i of sortedGroups
			set existingNumber to item 1 of existingGroup
			
			if groupNumber < existingNumber then
				set sortedGroups to insertItem(groupInfo, i, sortedGroups)
				set inserted to true
				exit repeat
			end if
		end repeat
		
		if not inserted then
			set end of sortedGroups to groupInfo
		end if
	end repeat
	
	return sortedGroups
end sortGroupsByNumber

-- NEW: Parse number selection (supports ranges like 1-5)
on parseNumberSelection(userInput, maxIndex)
	set selectedIndices to {}
	
	-- Parse comma-separated values
	set AppleScript's text item delimiters to ","
	set inputParts to text items of userInput
	set AppleScript's text item delimiters to ""
	
	repeat with part in inputParts
		set cleanPart to trimWhitespace(part as string)
		
		-- Check if it's a range (e.g., "1-5")
		if cleanPart contains "-" then
			set rangeParts to text items of cleanPart
			if (count of rangeParts) is 2 then
				set startNum to trimWhitespace(item 1 of rangeParts) as number
				set endNum to trimWhitespace(item 2 of rangeParts) as number
				
				-- Add all numbers in range
				repeat with i from startNum to endNum
					if i ≥ 1 and i ≤ maxIndex then
						if i is not in selectedIndices then
							set end of selectedIndices to i
						end if
					end if
				end repeat
			end if
		else
			-- Single number
			try
				set num to cleanPart as number
				if num ≥ 1 and num ≤ maxIndex then
					if num is not in selectedIndices then
						set end of selectedIndices to num
					end if
				end if
			on error
				-- Skip invalid numbers
			end try
		end if
	end repeat
	
	return selectedIndices
end parseNumberSelection

-- NEW: Insert item at specific position
on insertItem(itemToInsert, position, list)
	set newList to {}
	
	repeat with i from 1 to (count of list)
		if i is position then
			set end of newList to itemToInsert
		end if
		set end of newList to item i of list
	end repeat
	
	if position > (count of list) then
		set end of newList to itemToInsert
	end if
	
	return newList
end insertItem

-- NEW: Scan and index all camera files in folder
on scanAndIndexFiles(sourceFolder)
	set cameraFiles to {}
	set fileIndex to {}
	
	try
		tell application "Finder"
			set allFiles to every file in folder (sourceFolder as alias)
		end tell
		
		repeat with fileItem in allFiles
			try
				tell application "Finder"
					set fileName to name of fileItem
					set fileExtension to name extension of fileItem
				end tell
				
				-- Check if it's a camera file
				if isCameraFile(fileName, fileExtension) then
					set end of cameraFiles to fileName
					
					-- Extract number from filename for indexing
					set fileNumber to extractNumberFromFileName(fileName)
					if fileNumber is not "" then
						if fileIndex does not contain fileNumber then
							set end of fileIndex to fileNumber
						end if
					end if
				end if
			on error errMsg
				-- Skip files that can't be read
			end try
		end repeat
		
	on error errMsg
		-- Return empty lists if folder can't be scanned
	end try
	
	return {cameraFiles, fileIndex}
end scanAndIndexFiles

-- NEW: Extract number from filename
on extractNumberFromFileName(fileName)
	-- Remove extension first
	set nameWithoutExt to getFileNameWithoutExtension(fileName)
	
	-- Look for number patterns in the filename
	-- Common patterns: DSC05714, IMG_1234, P1234567, etc.
	set numberPatterns to {"DSC", "IMG_", "P", "DSCF", "IMGP", "GOPR", "GP", "DJI_"}
	
	repeat with pattern in numberPatterns
		if nameWithoutExt starts with pattern then
			set numberPart to text (length of pattern + 1) thru -1 of nameWithoutExt
			if isNumeric(numberPart) then
				return numberPart
			end if
		end if
	end repeat
	
	-- Also check if the filename itself is numeric
	if isNumeric(nameWithoutExt) then
		return nameWithoutExt
	end if
	
	-- Look for any sequence of digits in the filename
	set digitSequence to extractDigits(nameWithoutExt)
	if digitSequence is not "" then
		return digitSequence
	end if
	
	return ""
end extractNumberFromFileName

-- NEW: Check if string is numeric
on isNumeric(str)
	try
		str as number
		return true
	on error
		return false
	end try
end isNumeric

-- NEW: Extract digits from string
on extractDigits(str)
	set digits to ""
	repeat with i from 1 to length of str
		set char to character i of str
		if char is in {"0", "1", "2", "3", "4", "5", "6", "7", "8", "9"} then
			set digits to digits & char
		end if
	end repeat
	return digits
end extractDigits

-- NEW: Copy single file with error handling
on copySingleFile(fileName, sourceFolder, destFolder)
	set sourcePath to (sourceFolder as string) & fileName
	set destPath to (destFolder as string) & fileName
	
	try
		-- Check if source file exists
		set sourceAlias to sourcePath as alias
		
		-- Check if destination file already exists
		try
			set destAlias to destPath as alias
			-- File exists, ask user what to do
			set userChoice to button returned of (display dialog "File already exists: " & fileName & "
			
What would you like to do?" buttons {"Skip", "Rename", "Overwrite"} default button "Skip" with icon caution)
			
			if userChoice is "Skip" then
				return {0, {}}
			else if userChoice is "Rename" then
				set destPath to getUniqueFileName(destFolder, fileName)
				do shell script "cp " & quoted form of POSIX path of sourcePath & " " & quoted form of POSIX path of destPath
				return {1, {}}
			else if userChoice is "Overwrite" then
				do shell script "cp " & quoted form of POSIX path of sourcePath & " " & quoted form of POSIX path of destPath
				return {1, {}}
			end if
		on error
			-- File doesn't exist in destination, safe to copy
			do shell script "cp " & quoted form of POSIX path of sourcePath & " " & quoted form of POSIX path of destPath
			return {1, {}}
		end try
		
	on error errMsg
		return {0, {fileName & ": " & errMsg}}
	end try
end copySingleFile

-- Function to copy all camera files (existing functionality)
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
					set {copied, errors} to copySingleFile(fileName, sourceFolder, destFolder)
					set copiedCount to copiedCount + copied
					set errorList to errorList & errors
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
		set allPatterns to {"DSC", "IMG", "_DSC", "IMG_", "_MG_", "MVI_", "DSC_", "DSCF", "_DSF", "P", "PA", "PB", "PC", "PD", "PE", "PF", "PG", "PH", "PI", "PJ", "PK", "PL", "PM", "PN", "PO", "PP", "PQ", "PR", "PS", "PT", "PU", "PV", "PW", "PX", "PY", "PZ", "IMGP", "_IGP", "L", "GOPR", "GP", "DJI_"}
		
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