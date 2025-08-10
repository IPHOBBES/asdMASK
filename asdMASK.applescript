-- asdMASK Control Script
-- This script provides functionality to hide/unhide .asd files in specific folders or all mounted volumes

on run
	-- First step: Ask whether the user wants to process files in a specific folder or all mounted volumes
	try
		set locationChoice to display alert "Choose the scope for processing .asd files:" buttons {"Specific Folder", "All Mounted Drives", "Cancel"} default button "Specific Folder" cancel button "Cancel"
	on error
		return -- Exit the script if Cancel is pressed
	end try
	
	set locationAction to button returned of locationChoice
	
	-- Second step: Ask whether the user wants to hide or unhide .asd files
	try
		set actionChoice to display alert "Do you want to hide or unhide .asd files?" buttons {"Hide .asd Files", "Unhide .asd Files", "Cancel"} default button "Hide .asd Files" cancel button "Cancel"
	on error
		return -- Exit the script if Cancel is pressed
	end try
	
	set fileAction to button returned of actionChoice
	
	-- If user selects "In Folder"
	if locationAction is "Specific Folder" then
		-- Prompt the user to select a folder
		set chosenFolder to choose folder with prompt "Select a folder to process .asd files:"
		set folderPath to quoted form of POSIX path of chosenFolder -- Properly quote the folder path
	else if locationAction is "All Mounted Drives" then
		-- Get the list of all mounted volumes, excluding the system volume
		set allVolumes to paragraphs of (do shell script "ls /Volumes")
		
		-- Initialize an empty string for folder paths
		set folderPath to ""
		
		-- Loop through all volumes and append them to the folderPath string
		repeat with volumeName in allVolumes
			set folderPath to folderPath & quoted form of ("/Volumes/" & volumeName) & " "
		end repeat
	end if
	
	-- Determine whether to hide or unhide and initialize list for processed files
	set processedFiles to "" -- To store the list of processed files
	if fileAction is "Hide .asd Files" then
		-- Check if there are any files that are NOT hidden
		set asdFilesCount to do shell script "find " & folderPath & " -type f -name '*.asd' ! -flags hidden | wc -l"
		set asdFilesCount to asdFilesCount as integer -- Convert to integer for comparison
		
		if asdFilesCount is 0 then
			display alert "No Files to Hide" message "There are no .asd files to hide in the selected location." buttons {"OK"} default button "OK"
		else
			-- Hide the files and collect the list of files hidden
			set processedFiles to do shell script "find " & folderPath & " -type f -name '*.asd' ! -flags hidden -exec chflags hidden {} \\; -print"
			display alert "Process Completed" message (asdFilesCount as string) & " .asd files have been hidden." buttons {"OK"} default button "OK"
		end if
		
	else if fileAction is "Unhide .asd Files" then
		-- Check if there are any files that are hidden
		set asdFilesCount to do shell script "find " & folderPath & " -type f -name '*.asd' -flags hidden | wc -l"
		set asdFilesCount to asdFilesCount as integer -- Convert to integer for comparison
		
		if asdFilesCount is 0 then
			display alert "No Files to Unhide" message "There are no .asd files to unhide in the selected location." buttons {"OK"} default button "OK"
		else
			-- Unhide the files and collect the list of files unhidden
			set processedFiles to do shell script "find " & folderPath & " -type f -name '*.asd' -flags hidden -exec chflags nohidden {} \\; -print"
			display alert "Process Completed" message (asdFilesCount as string) & " .asd files have been unhidden." buttons {"OK"} default button "OK"
		end if
	end if
	
	-- Prompt the user if they want to save the list of processed files to a text file
	if processedFiles is not "" then
		set saveChoice to display alert "Do you want to save the list of processed files to a text file?" buttons {"Yes", "No"} default button "Yes" cancel button "No"
		
		if button returned of saveChoice is "Yes" then
			-- Set the file path to save the list (Desktop folder and file name depending on action)
			set fileName to "hidden_asd.txt"
			if fileAction is "Unhide .asd Files" then
				set fileName to "unhidden_asd.txt"
			end if
			
			set filePath to (POSIX path of (path to desktop)) & fileName
			
			-- Save the processed files to the text file
			try
				-- Use 'printf' instead of 'echo' to handle newlines and file paths better
				do shell script "printf '%s\n' " & quoted form of processedFiles & " > " & quoted form of filePath
				display alert "Text File Saved" message "The list of processed files has been saved to your desktop as " & fileName buttons {"OK"} default button "OK"
			on error errMsg
				display alert "Error" message "An error occurred while saving the file: " & errMsg buttons {"OK"} default button "OK"
			end try
		end if
	end if
end run 