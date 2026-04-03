$src = 'android\app\src\main\res\mipmap-hdpi\ic_launcher.png'
$backup = 'android\app\src\main\res\mipmap-hdpi\ic_launcher.cover.bak'
if (Test-Path $src) { Copy-Item $src $backup -Force }
Add-Type -AssemblyName System.Drawing
$img = [System.Drawing.Image]::FromFile($src)
$size = 1024
$temp = "$env:TEMP\\ic_launcher_temp.png"
if (Test-Path $temp) { Remove-Item $temp -Force }
$canvas = New-Object System.Drawing.Bitmap $size, $size
$g = [System.Drawing.Graphics]::FromImage($canvas)
$g.Clear([System.Drawing.Color]::White)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
# Use cover scaling (max) so the image fills the canvas
$ratio = [math]::Max($size / $img.Width, $size / $img.Height)
$newW = [int]([math]::Ceiling($img.Width * $ratio))
$newH = [int]([math]::Ceiling($img.Height * $ratio))
$x = [int](($size - $newW) / 2)
$y = [int](($size - $newH) / 2)
$g.DrawImage($img, $x, $y, $newW, $newH)
# Save to temp file then move to avoid GDI+ locked-write issues
$canvas.Save($temp, [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose()
$img.Dispose()
$canvas.Dispose()
Move-Item -Force $temp $src
Write-Output 'CompositedCoverDone'
