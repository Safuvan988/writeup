Add-Type -AssemblyName System.Drawing

$src = Join-Path $PSScriptRoot "assets\images\logo.png"
$dst = Join-Path $PSScriptRoot "assets\images\launcher_icon.png"

$img  = [System.Drawing.Image]::FromFile($src)
$pad  = [int]($img.Width * 0.22)
$size = $img.Width + 2 * $pad

$bmp = New-Object System.Drawing.Bitmap($size, $size)
$g   = [System.Drawing.Graphics]::FromImage($bmp)
$g.Clear([System.Drawing.Color]::Transparent)
$g.DrawImage($img, $pad, $pad, $img.Width, $img.Height)

$bmp.Save($dst, [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose()
$bmp.Dispose()
$img.Dispose()

Write-Host "Done: $dst"
