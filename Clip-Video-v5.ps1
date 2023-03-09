Param(
[string]$format="mp4",
[string]$invid,
[string]$outvid,
[string]$cut1,
[string]$cut2
)
# Clear-Host
# New-Item -ItemType Directory -Path "clips" -ErrorAction SilentlyContinue
if ($invid) {
    # Code to process a single video, currently copied from multi
    $outvid = $invid -replace ".$format", "-clipped-$($cut1.replace(":","m"))-$($cut2.replace(":","m")).$format"
    "cut1: $cut1, cut2: $cut2, outvid: $outvid"
    try {if ($cut2.ToInt32($Null) -eq 0) {$strCmd = "Trim"}} catch {$strCmd = "Clip"}
    try {
        if ($strCmd -eq "Trim") {
            $cmd = "ffmpeg -ss ""00:$cut1"" -i ""$invid"" -c copy ""$outvid"""
            $cmd
            ffmpeg -ss "00:$cut1" -i "$invid" -c copy "$outvid"
        } else {
            $cmd = "ffmpeg -ss ""00:$cut1"" -t ""00:$cut2"" -i ""$invid"" -c copy ""$outvid"""
            $cmd
            ffmpeg -ss "00:$cut1" -t "00:$cut2" -i "$invid" -c copy "$outvid"
        }
    } catch {
        "ERROR: Clipping failed";return
    }
    "STATUS: Clipping was successful"
    # Read-Host -Prompt "Press Any Key to Continue..."
    # Move-Item $outvid ".\clips" 
    $f = Get-ChildItem $invid
    $newPath = $f.fullname.replace("$($f.name)","")+"originals"
    New-Item -ItemType Directory -Path $newPath -ErrorAction SilentlyContinue
    Move-Item $invid $newPath 
    # Clear-Host
} else {
    $Finished = $false
    Do {
        $vidlist = @()
        Get-ChildItem "*.$format" | % {
            $viditemvalue = $_.Name
            $viditem = New-Object -TypeName PSObject
            $viditem | Add-Member -MemberType NoteProperty -Name "Name" -Value $viditemvalue
            $vidlist += $viditem
        }
        $vidindex = 0
        $vidlist | % {"$vidindex : $($_.Name)"; $vidindex ++}
        $vidselect = Read-Host -Prompt "Which Video to clip? (Q to Quit)"
        if ($vidselect -eq "Q" -or $vidselect -eq "q") {return}
        $invid = $vidlist[$vidselect].Name
        $cut1 = (Read-Host -Prompt "Clip start time?")
        $cut2 = (Read-Host -Prompt "Clip duration?")
        $outvid = $invid -replace ".$format", "-clipped-$cut1-$cut2.$format" -replace ":", ""
        "cut1: $cut1, cut2: $cut2, outvid: $outvid"
        try {if ($cut2.ToInt32($Null) -eq 0) {$strCmd = "Trim"}} catch {$strCmd = "Clip"}
        try {
            if ($strCmd -eq "Trim") {
                $cmd = "ffmpeg -ss ""00:$cut1"" -i ""$invid"" -c copy ""$outvid"""
                $cmd
                ffmpeg -ss "00:$cut1" -i "$invid" -c copy "$outvid"
            } else {
                $cmd = "ffmpeg -ss ""00:$cut1"" -t ""00:$cut2"" -i ""$invid"" -c copy ""$outvid"""
                $cmd
                ffmpeg -ss "00:$cut1" -t "00:$cut2" -i "$invid" -c copy "$outvid"
            }
        } catch {
            "ERROR: Clipping failed";return
        }
        "STATUS: Clipping was successful"
        # Read-Host -Prompt "Press Any Key to Continue..."
        # Move-Item $outvid ".\clips" 
        New-Item -ItemType Directory -Path "originals" -ErrorAction SilentlyContinue
        Move-Item $invid ".\originals" 
        # Clear-Host
    } Until ($Finished)
}