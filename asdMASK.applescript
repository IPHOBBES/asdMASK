-- asdMASK Control Script v5
-- Hide / unhide .asd files in a specific folder or selected mounted drives
-- Adds start/finish notifications for a nicer UX

on run
	-- Step 1: Ask scope
	try
		set locationChoice to display alert "Choose the scope for processing .asd files:" buttons {"Specific Folder", "Choose Mounted Drive(s)", "Cancel"} default button "Specific Folder" cancel button "Cancel"
	on error
		return
	end try
	
	set locationAction to button returned of locationChoice
	
	-- Step 2: Ask action
	try
		set actionChoice to display alert "Do you want to hide or unhide .asd files?" buttons {"Hide .asd Files", "Unhide .asd Files", "Cancel"} default button "Hide .asd Files" cancel button "Cancel"
	on error
		return
	end try
	
	set fileAction to button returned of actionChoice
	
	-- Step 3: Build target paths
	set targetPaths to {}
	set targetNames to {}
	
	if locationAction is "Specific Folder" then
		try
			set chosenFolder to choose folder with prompt "Select a folder to process .asd files:"
			set end of targetPaths to POSIX path of chosenFolder
			set end of targetNames to name of (info for chosenFolder)
		on error
			return
		end try
		
	else if locationAction is "Choose Mounted Drive(s)" then
		set volumeChoices to my getMountedVolumes()
		
		if volumeChoices is {} then
			display alert "No Mounted Drives Found" message "There are no mounted drives available to process." buttons {"OK"} default button "OK"
			return
		end if
		
		try
			set selectedVolumes to choose from list volumeChoices with prompt "Select one or more mounted drives to process:" with multiple selections allowed default items {}
		on error
			return
		end try
		
		if selectedVolumes is false then return
		
		repeat with volumeName in selectedVolumes
			set end of targetPaths to "/Volumes/" & volumeName
			set end of targetNames to (contents of volumeName)
		end repeat
	end if
	
	if targetPaths is {} then return
	
	-- Step 4: Warn user before long processing
	set targetCount to count of targetPaths
	
	if targetCount is 1 then
		set scopeText to item 1 of targetNames
	else
		set scopeText to (targetCount as string) & " selected locations"
	end if
	
	try
		display alert "Ready to Process" message "The script is about to process " & scopeText & "." & return & return & "This may take a while on large drives or network volumes." buttons {"Continue", "Cancel"} default button "Continue" cancel button "Cancel"
	on error
		return
	end try
	
	-- Step 5: Start notification
	if fileAction is "Hide .asd Files" then
		display notification "Processing has started for " & scopeText & "." with title "asdMASK" subtitle "Hiding .asd files"
	else
		display notification "Processing has started for " & scopeText & "." with title "asdMASK" subtitle "Unhiding .asd files"
	end if
	
	-- Step 6: Temporary report file
	set tempReportFile to do shell script "mktemp /tmp/asdmask_report.XXXXXX"
	do shell script ": > " & quoted form of tempReportFile
	
	set totalCount to 0
	set processedTargets to 0
	
	-- Step 7: Process each target
	repeat with i from 1 to targetCount
		set posixTarget to item i of targetPaths
		set targetLabel to item i of targetNames
		set quotedTarget to quoted form of posixTarget
		
		try
			if fileAction is "Hide .asd Files" then
				set fileCount to do shell script "find " & quotedTarget & " -type f -name '*.asd' ! -flags hidden 2>/dev/null | wc -l | tr -d ' '"
				set fileCount to fileCount as integer
				
				if fileCount > 0 then
					do shell script "find " & quotedTarget & " -type f -name '*.asd' ! -flags hidden -exec chflags hidden {} \\; -print 2>/dev/null >> " & quoted form of tempReportFile
				end if
				
			else if fileAction is "Unhide .asd Files" then
				set fileCount to do shell script "find " & quotedTarget & " -type f -name '*.asd' -flags hidden 2>/dev/null | wc -l | tr -d ' '"
				set fileCount to fileCount as integer
				
				if fileCount > 0 then
					do shell script "find " & quotedTarget & " -type f -name '*.asd' -flags hidden -exec chflags nohidden {} \\; -print 2>/dev/null >> " & quoted form of tempReportFile
				end if
			end if
			
			set totalCount to totalCount + fileCount
			set processedTargets to processedTargets + 1
			
		on error errMsg
			display alert "Error" message "An error occurred while processing:" & return & targetLabel & return & return & errMsg buttons {"OK"} default button "OK"
		end try
	end repeat
	
	-- Step 8: If nothing processed, clean up and stop
	if totalCount is 0 then
		do shell script "rm -f " & quoted form of tempReportFile
		
		if fileAction is "Hide .asd Files" then
			display notification "No .asd files needed hiding." with title "asdMASK" subtitle "Finished"
			display alert "No Files to Hide" message "There are no .asd files to hide in the selected location." buttons {"OK"} default button "OK"
		else
			display notification "No .asd files needed unhiding." with title "asdMASK" subtitle "Finished"
			display alert "No Files to Unhide" message "There are no .asd files to unhide in the selected location." buttons {"OK"} default button "OK"
		end if
		
		return
	end if
	
	-- Step 9: Ask about report only after real processing
	set saveReport to false
	try
		set saveChoice to display alert "Do you want to save the list of processed files to a text file?" buttons {"Yes", "No"} default button "Yes" cancel button "No"
		if button returned of saveChoice is "Yes" then set saveReport to true
	on error
		set saveReport to false
	end try
	
	if saveReport then
		set timeStamp to do shell script "date +%Y-%m-%d_%H-%M-%S"
		
		if fileAction is "Hide .asd Files" then
			set reportFileName to "hidden_asd_" & timeStamp & ".txt"
		else
			set reportFileName to "unhidden_asd_" & timeStamp & ".txt"
		end if
		
		set reportFilePath to (POSIX path of (path to desktop)) & reportFileName
		
		try
			do shell script "cp " & quoted form of tempReportFile & " " & quoted form of reportFilePath
			do shell script "rm -f " & quoted form of tempReportFile
			
			if fileAction is "Hide .asd Files" then
				display notification ((totalCount as string) & " .asd files hidden.") with title "asdMASK" subtitle "Finished"
				display alert "Process Completed" message ((totalCount as string) & " .asd files have been hidden across " & (processedTargets as string) & " location(s)." & return & return & "The list of processed files has been saved to your desktop as " & reportFileName) buttons {"OK"} default button "OK"
			else
				display notification ((totalCount as string) & " .asd files unhidden.") with title "asdMASK" subtitle "Finished"
				display alert "Process Completed" message ((totalCount as string) & " .asd files have been unhidden across " & (processedTargets as string) & " location(s)." & return & return & "The list of processed files has been saved to your desktop as " & reportFileName) buttons {"OK"} default button "OK"
			end if
			
		on error errMsg
			do shell script "rm -f " & quoted form of tempReportFile
			display alert "Error" message "An error occurred while saving the file: " & errMsg buttons {"OK"} default button "OK"
		end try
	else
		do shell script "rm -f " & quoted form of tempReportFile
		
		if fileAction is "Hide .asd Files" then
			display notification ((totalCount as string) & " .asd files hidden.") with title "asdMASK" subtitle "Finished"
			display alert "Process Completed" message ((totalCount as string) & " .asd files have been hidden across " & (processedTargets as string) & " location(s).") buttons {"OK"} default button "OK"
		else
			display notification ((totalCount as string) & " .asd files unhidden.") with title "asdMASK" subtitle "Finished"
			display alert "Process Completed" message ((totalCount as string) & " .asd files have been unhidden across " & (processedTargets as string) & " location(s).") buttons {"OK"} default button "OK"
		end if
	end if
end run

on getMountedVolumes()
	try
		set volumeList to paragraphs of (do shell script "find /Volumes -mindepth 1 -maxdepth 1 -type d -print 2>/dev/null | sed 's#^/Volumes/##' | sort")
		set cleanedList to {}
		
		repeat with volumeName in volumeList
			set volumeName to contents of volumeName
			if volumeName is not "" and volumeName is not "EFI" and volumeName does not start with "." then
				set end of cleanedList to volumeName
			end if
		end repeat
		
		return cleanedList
	on error
		return {}
	end try
end getMountedVolumes
