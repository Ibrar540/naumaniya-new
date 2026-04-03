$src = 'android\app\src\main\res\mipmap-hdpi\ic_launcher.png'
$backup = 'android\app\src\main\res\mipmap-hdpi\ic_launcher.cover.bak'
$temp = 'android\app\src\main\res\mipmap-hdpi\ic_launcher.tmp.png'
if (Test-Path $src) { Copy-Item $src $backup -Force }
Add-Type -AssemblyName System.Drawing
$img = [System.Drawing.Image]::FromFile($src)
$size = 1024
$canvas = New-Object System.Drawing.Bitmap $size, $size
$g = [System.Drawing.Graphics]::FromImage($canvas)
$g.Clear([System.Drawing.Color]::White)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
# Cover scaling: scale so smallest dimension fills
$ratio = [math]::Max($size / $img.Width, $size / $img.Height)
$newW = [int]($img.Width * $ratio)
$newH = [int]($img.Height * $ratio)
$x = [int](($size - $newW) / 2)
$y = [int](($size - $newH) / 2)
$g.DrawImage($img, $x, $y, $newW, $newH)
# Save to temp file then replace original
$canvas.Save($temp, [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose()
$img.Dispose()
$canvas.Dispose()
Move-Item -Force -LiteralPath $temp -Destination $src
Write-Output 'CompositedCoverSaved'
