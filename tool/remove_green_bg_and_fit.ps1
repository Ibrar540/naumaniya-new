# Detect green pixels by HSV hue range and replace with white, then contain-fit into 1024x1024
$src = 'android\app\src\main\res\mipmap-hdpi\ic_launcher.png'
$backup = 'android\app\src\main\res\mipmap-hdpi\ic_launcher.green.bak'
$temp = 'android\app\src\main\res\mipmap-hdpi\ic_launcher.tmp.png'
if (-not (Test-Path $src)) { Write-Error "Source not found: $src"; exit 1 }
Copy-Item $src $backup -Force
Add-Type -AssemblyName System.Drawing
$bmp = [System.Drawing.Bitmap]::FromFile($src)
$w = $bmp.Width; $h = $bmp.Height
function RGBtoHSV($r,$g,$b){
    $rD = $r/255.0; $gD = $g/255.0; $bD = $b/255.0
    $max = [Math]::Max($rD,[Math]::Max($gD,$bD))
    $min = [Math]::Min($rD,[Math]::Min($gD,$bD))
    $d = $max - $min
    if ($d -eq 0){ $h=0 }
    else{
        switch ($max){
            ($max -eq $rD){ $h = 60 * ((($gD - $bD)/$d) % 6) }
            ($max -eq $gD){ $h = 60 * ((($bD - $rD)/$d) + 2) }
            default { $h = 60 * ((($rD - $gD)/$d) + 4) }
        }
    }
    if ($h -lt 0){ $h += 360 }
    if ($max -eq 0) { $s = 0 } else { $s = ($d / $max) }
    $v = $max
    return @{H=$h; S=$s; V=$v}
}
# Parameters: hue range and sat/value thresholds for green
$hMin = 70; $hMax = 170; # degrees for green-ish
$sMin = 0.15; $vMin = 0.12
# Iterate pixels and replace greenish pixels with white
for ($x=0; $x -lt $w; $x++){
    for ($y=0; $y -lt $h; $y++){
        $c = $bmp.GetPixel($x,$y)
        # ignore fully transparent pixels
        if ($c.A -lt 10){ continue }
        $hsv = RGBtoHSV $c.R $c.G $c.B
        $h = $hsv.H; $s = $hsv.S; $v = $hsv.V
        if (($h -ge $hMin -and $h -le $hMax) -and ($s -ge $sMin) -and ($v -ge $vMin)){
            $bmp.SetPixel($x,$y,[System.Drawing.Color]::FromArgb(255,255,255,255))
        }
    }
}
# Contain-fit into 1024x1024 white canvas
$size = 1024
$canvas = New-Object System.Drawing.Bitmap $size, $size
$g = [System.Drawing.Graphics]::FromImage($canvas)
$g.Clear([System.Drawing.Color]::White)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$ratio = [math]::Min($size / $bmp.Width, $size / $bmp.Height)
$newW = [int]($bmp.Width * $ratio); $newH = [int]($bmp.Height * $ratio)
$x0 = [int](($size - $newW)/2); $y0 = [int](($size - $newH)/2)
$g.DrawImage($bmp, $x0, $y0, $newW, $newH)
$canvas.Save($temp, [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $bmp.Dispose(); $canvas.Dispose()
Move-Item -Force -LiteralPath $temp -Destination $src
Write-Output 'Green background removed and image fitted (contain). Backup at: ' $backup
