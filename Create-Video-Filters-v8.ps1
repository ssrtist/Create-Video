# Nextgen version 4
# Fixed intro subfolder, added video sequence number
# Nextgen version 3
# Added intro folders, revised single folder routine

Param(
[String]$directory,
[String]$BitrateVideo="20M",
[String]$BitrateAudio="160K",
[Switch]$LoudNorm,
[ValidateSet(30,60)][String]$FPS=60,
[ValidateSet("Name","CreationTime")][String]$SortBy="Name",
[Switch]$NoFilter,
[Switch]$NoIntro
)

Function Rename-Videofile()
{
Param(    
    [String]$thisfolder
)
    Get-ChildItem $thisfolder\* | ForEach-Object {
        Rename-Item -Path $_.FullName -NewName ($_.name.split("-").split("_").PadLeft(2,'0') -join "-").replace("e-","e_") -ErrorAction SilentlyContinue
    }
}
Function Filter-Video()
{
Param(
    [String]$filtering
)
    New-Item -ItemType Directory -Path ".\$filtering\filtered" -ErrorAction SilentlyContinue
    # First list the files before processing
    "Video files to be processed:`n`n"
    if ($NoIntro) {$Intro=""} else {$Intro=".\Intro\*"}
    $Intro
    Get-ChildItem ".\$filtering\Intro\*", "$Intro", ".\$filtering\*", ".\Outtro\*" -Include *.mp4,*.mov,*.mkv -ErrorAction SilentlyContinue | ForEach-Object {$_.fullname}
    # Process videos
    $videoSN = 0
    Get-ChildItem ".\$filtering\Intro\*", "$Intro", ".\$filtering\*", ".\Outtro\*" -Include *.mp4,*.mov,*.mkv -ErrorAction SilentlyContinue | ForEach-Object {
        $videoSN++
        if ($LoudNorm) {
            ffmpeg.exe -i "$($_.fullname)" -c:v h264_nvenc -filter:v "scale=1920:1080,fps=$FPS,format=yuv420p" -filter:a "loudnorm" -b:v "$BitrateVideo" -b:a "$BitrateAudio" -ar 44100 "$filtering\filtered\$($videoSN.ToString().PadLeft(2,'0')).filtered-$($_.name)"
        } else {
            ffmpeg.exe -i "$($_.fullname)" -c:v h264_nvenc -filter:v "scale=1920:1080,fps=$FPS,format=yuv420p"                      -b:v "$BitrateVideo" -b:a "$BitrateAudio" -ar 44100 "$filtering\filtered\$($videoSN.ToString().PadLeft(2,'0')).filtered-$($_.name)"
        }
    }
}

Function Trim-VideoFile()
{
Param(    
    [String]$thisfolder
)
    Get-ChildItem $thisfolder\*.mp4 | ForEach-Object {
        $thisfile = $_.fullname
        if (!($thisfile.split("(")[1])) {
            "$thisfile : No Processing Command"
        } else {
            "$thisfile : Trimming..."
            $thisfile.split("(")[1].split(")")[0].split(";") | ForEach-Object {
                $cmd=$_.split(" ")[0]
                $pram=$_.split(" ")[1].replace("m",":")
                $pram2=$_.split(" ")[2].replace("m",":")
                "Command: $cmd `nParameter: $pram"; 
                switch ($cmd) {
                    "trim" {
                        ".\Clip-Video-v5.ps1 -invid $thisfile -cut1 $pram -cut2 00"
                        .\Clip-Video-v5.ps1 -invid $thisfile -cut1 $pram -cut2 00
                        } 
                    "clip" {
                        ".\Clip-Video-v5.ps1 -invid $thisfile -cut1 $pram -cut2 $parm2"
                        .\Clip-Video-v5.ps1 -invid $thisfile -cut1 $pram -cut2 $pram2
                    }
                }
            }
        }
        # Rename-Item -Path $_.FullName -NewName ($_.name.split("-").split("_").PadLeft(2,'0') -join "-").replace("e-","e_") -ErrorAction SilentlyContinue
    }
}

Function Join-VideoFile()
{
Param(
    [String]$processing
)

    $tempcfg = "zzz - temp\processing.txt"
    $tempvid = "zzz - temp\temp.mp4"

    # Retrieve folders matching patern
    $folderlist = @()
    if (!$processing) { 
        "$(get-date -Format 'yyyy-MM-ddThh:mm:ss') : No directory to process: Generating list"
        Get-ChildItem -Directory * | Where-Object {$_.Name -notlike 'zzz*'} | ForEach-Object {
            $folderitemvalue = $_.Name
            $folderitem = New-Object -TypeName PSObject
            $folderitem | Add-Member -MemberType NoteProperty -Name "Name" -Value $folderitemvalue
            $folderlist += $folderitem
        }
        $folderindex = 1
        $folderlist | ForEach-Object {"$folderindex : $($_.Name)"; $folderindex ++}
        $processing = $folderlist[(Read-Host -Prompt "Which Folder To Join? (Type ""all"" for all folders)") - 1].Name
    }
    # Folder selected, process selected folder
    if ($processing) {
        "$(get-date -Format 'yyyy-MM-ddThh:mm:ss') : Directory to process: $processing"
        Rename-Videofile $processing # rename files with padded zeros
        $output = "$($processing.replace('.\','').replace('\','').replace('(1)','1'))-$(get-date -Format "yyyy-MM-dd-hh-mm-ss").mp4"
        if (!$NoFilter) {Filter-Video $processing} else {Copy-Item .\$processing\* -Include *.mp4,*.mov,*.mkv -Destination .\$processing\filtered -Force}
        (Get-ChildItem "$processing\filtered\*" -Include *.mp4,*.mov,*.mkv | Sort-Object -Property $SortBy).fullname | ForEach-Object {"file '$_'"} | out-file -Encoding ascii $tempcfg
        if (Test-Path $tempvid) {Remove-Item $tempvid -force}
        ffmpeg.exe -f concat -safe 0 -vsync 0 -hwaccel cuvid -c:v h264_cuvid -i $tempcfg -c:v h264_nvenc -b:v "$BitrateVideo" "$output"
        if (!$NoFilter) {remove-item "$processing\filtered" -Recurse -Force}
        return
    }
}

if (!(Get-Item ".\zzz - temp\" -ErrorAction SilentlyContinue)) {New-Item -ItemType Directory -Name "zzz - temp"}
Trim-VideoFile $directory
Join-VideoFile $directory