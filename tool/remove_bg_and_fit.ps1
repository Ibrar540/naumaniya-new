# Replace uniform background color (estimated from corners) with white, then fit image into 1024x1024 (contain)
$src = 'android\app\src\main\res\mipmap-hdpi\ic_launcher.png'
$backup = 'android\app\src\main\res\mipmap-hdpi\ic_launcher.bg.bak'
$temp = 'android\app\src\main\res\mipmap-hdpi\ic_launcher.tmp.png'
if (-not (Test-Path $src)) { Write-Error "Source not found: $src"; exit 1 }
Copy-Item $src $backup -Force
Add-Type -AssemblyName System.Drawing
$bmp = [System.Drawing.Bitmap]::FromFile($src)
$w = $bmp.Width; $h = $bmp.Height
# sample 8x8 patches at corners
function avgColor($bmp,$x0,$y0,$w,$h){
  $r=0; $g=0; $b=0; $count=0
  for($x=$x0; $x -lt $x0+$w; $x++){ for($y=$y0; $y -lt $y0+$h; $y++){ if($x -ge 0 -and $x -lt $bmp.Width -and $y -ge 0 -and $y -lt $bmp.Height){ $c = $bmp.GetPixel($x,$y); $r+=$c.R; $g+=$c.G; $b+=$c.B; $count++ }}}
  return @{R=[int]($r/$count); G=[int]($g/$count); B=[int]($b/$count)}
}
$patch = [math]::Min(12, [math]::Min([int]($w/6), [int]($h/6)))
$colors = @()
$colors += (avgColor $bmp 0 0 $patch $patch)
$colors += (avgColor $bmp ($w-$patch) 0 $patch $patch)
$colors += (avgColor $bmp 0 ($h-$patch) $patch $patch)
$colors += (avgColor $bmp ($w-$patch) ($h-$patch) $patch $patch)
# average corner colors
$R=0; $G=0; $B=0
foreach($c in $colors){ $R+=$c.R; $G+=$c.G; $B+=$c.B }
$bgR=[int]($R/$colors.Count); $bgG=[int]($G/$colors.Count); $bgB=[int]($B/$colors.Count)
Write-Output "Detected background color approx: R=$bgR G=$bgG B=$bgB"
# threshold distance
$threshold = 70
# replace near-bg pixels with white
for($x=0;$x -lt $bmp.Width;$x++){ for($y=0;$y -lt $bmp.Height;$y++){ $c = $bmp.GetPixel($x,$y); $dr=$c.R-$bgR; $dg=$c.G-$bgG; $db=$c.B-$bgB; $dist = [math]::Sqrt($dr*$dr + $dg*$dg + $db*$db)
    if($dist -le $threshold){ $bmp.SetPixel($x,$y,[System.Drawing.Color]::FromArgb(255,255,255,255)) }
}}
# Now create 1024x1024 contain fit on white
$size=1024
$canvas = New-Object System.Drawing.Bitmap $size, $size
$g=[System.Drawing.Graphics]::FromImage($canvas)
$g.Clear([System.Drawing.Color]::White)
$g.InterpolationMode=[System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$ratio = [math]::Min($size/$bmp.Width, $size/$bmp.Height)
$newW=[int]($bmp.Width*$ratio); $newH=[int]($bmp.Height*$ratio)
$x = [int](($size-$newW)/2); $y=[int](($size-$newH)/2)
$g.DrawImage($bmp,$x,$y,$newW,$newH)
$canvas.Save($temp,[System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $bmp.Dispose(); $canvas.Dispose()
Move-Item -Force -LiteralPath $temp -Destination $src
Write-Output 'Background replaced and contained image saved.'
