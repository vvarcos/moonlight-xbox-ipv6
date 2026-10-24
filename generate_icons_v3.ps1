Add-Type -AssemblyName System.Drawing

function CreateMoonlightIcon {
    param(
        [int]$size,
        [string]$outputPath
    )

    $bmp = [System.Drawing.Bitmap]::new($size, $size)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

    $g.Clear([System.Drawing.Color]::Transparent)

    $darkBlue = [System.Drawing.Color]::FromArgb(255, 10, 25, 55)
    $midBlue = [System.Drawing.Color]::FromArgb(255, 20, 60, 120)
    $teal = [System.Drawing.Color]::FromArgb(255, 0, 180, 160)
    $green = [System.Drawing.Color]::FromArgb(255, 0, 220, 140)
    $lightGreen = [System.Drawing.Color]::FromArgb(255, 100, 240, 180)

    $center = $size / 2
    $radius = $size * 0.42

    $bgRect = [System.Drawing.RectangleF]::new($center - $radius, $center - $radius, $radius * 2, $radius * 2)
    $bgPath = [System.Drawing.Drawing2D.GraphicsPath]::new()
    $bgPath.AddEllipse($bgRect)
    $bgBrush = [System.Drawing.Drawing2D.PathGradientBrush]::new($bgPath)
    $bgBrush.CenterColor = $midBlue
    $bgBrush.SurroundColors = @($darkBlue)
    $bgBrush.FocusScales = [System.Drawing.PointF]::new(0.3, 0.3)
    $g.FillEllipse($bgBrush, $bgRect)

    $moonRadius = $radius * 0.75
    $moonOffset = $radius * 0.15

    $moonRect = [System.Drawing.RectangleF]::new($center - $moonRadius + $moonOffset, $center - $moonRadius, $moonRadius * 2, $moonRadius * 2)
    $moonPath = [System.Drawing.Drawing2D.GraphicsPath]::new()
    $moonPath.AddEllipse($moonRect)
    $moonBrush = [System.Drawing.Drawing2D.PathGradientBrush]::new($moonPath)
    $moonBrush.CenterColor = $lightGreen
    $moonBrush.SurroundColors = @($teal)
    $moonBrush.FocusScales = [System.Drawing.PointF]::new(0.4, 0.4)
    $g.FillEllipse($moonBrush, $moonRect)

    $cutoutRadius = $moonRadius * 0.85
    $cutoutOffset = $moonOffset + $moonRadius * 0.35
    $cutoutRect = [System.Drawing.RectangleF]::new($center - $cutoutRadius + $cutoutOffset, $center - $cutoutRadius, $cutoutRadius * 2, $cutoutRadius * 2)
    $cutoutBrush = [System.Drawing.SolidBrush]::new($darkBlue)
    $g.FillEllipse($cutoutBrush, $cutoutRect)

    $glowRect = [System.Drawing.RectangleF]::new($center - $moonRadius + $moonOffset, $center - $moonRadius, $moonRadius * 2, $moonRadius * 2)
    $glowPath = [System.Drawing.Drawing2D.GraphicsPath]::new()
    $glowPath.AddEllipse($glowRect)
    $glowPen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(80, 100, 240, 180), $size * 0.015)
    $g.DrawEllipse($glowPen, $glowRect)

    if ($size -ge 44) {
        $sparkleX = $center + $moonRadius * 0.3
        $sparkleY = $center - $moonRadius * 0.3
        $sparkleSize = $size * 0.06
        $sparklePoints = @(
            [System.Drawing.PointF]::new($sparkleX, $sparkleY - $sparkleSize),
            [System.Drawing.PointF]::new($sparkleX + $sparkleSize * 0.3, $sparkleY - $sparkleSize * 0.3),
            [System.Drawing.PointF]::new($sparkleX + $sparkleSize, $sparkleY - $sparkleSize * 0.3),
            [System.Drawing.PointF]::new($sparkleX + $sparkleSize * 0.4, $sparkleY + $sparkleSize * 0.1),
            [System.Drawing.PointF]::new($sparkleX + $sparkleSize * 0.6, $sparkleY + $sparkleSize),
            [System.Drawing.PointF]::new($sparkleX, $sparkleY + $sparkleSize * 0.4),
            [System.Drawing.PointF]::new($sparkleX - $sparkleSize * 0.6, $sparkleY + $sparkleSize),
            [System.Drawing.PointF]::new($sparkleX - $sparkleSize * 0.4, $sparkleY + $sparkleSize * 0.1),
            [System.Drawing.PointF]::new($sparkleX - $sparkleSize, $sparkleY - $sparkleSize * 0.3),
            [System.Drawing.PointF]::new($sparkleX - $sparkleSize * 0.3, $sparkleY - $sparkleSize * 0.3)
        )
        $sparkleBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(220, 255, 255, 220))
        $g.FillPolygon($sparkleBrush, $sparklePoints)
    }

    $ringPen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(60, 0, 220, 140), $size * 0.008)
    $g.DrawEllipse($ringPen, $bgRect)

    $bmp.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose()
    $bmp.Dispose()
    Write-Host "Created: $outputPath (${size}x${size})"
}

# UWP uses ceiling for scale calculations
function GetScaledSize {
    param([int]$base, [int]$scale)
    return [Math]::Ceiling($base * $scale / 100)
}

$icons = @(
    @{ base=44;  name="Square44x44Logo" },
    @{ base=50;  name="StoreLogo" },
    @{ base=71;  name="SmallTile" },
    @{ base=150; name="Square150x150Logo" },
    @{ base=310; name="LargeTile" }
)

$scales = @(100, 125, 150, 200, 400)

foreach ($icon in $icons) {
    foreach ($scale in $scales) {
        $scaledSize = GetScaledSize -base $icon.base -scale $scale
        $outputPath = "G:\moonlight-xbox-ipv6\Assets\$($icon.name).scale-$scale.png"
        CreateMoonlightIcon -size $scaledSize -outputPath $outputPath
    }
}

# Wide tile (310x150) - exact sizes using ceiling
$wideScales = @(
    @{ scale=100; w=310; h=150 },
    @{ scale=125; w=388; h=188 },
    @{ scale=150; w=465; h=225 },
    @{ scale=200; w=620; h=300 },
    @{ scale=400; w=1240; h=600 }
)

foreach ($ws in $wideScales) {
    $outputPath = "G:\moonlight-xbox-ipv6\Assets\Wide310x150Logo.scale-$($ws.scale).png"
    
    $bmp = [System.Drawing.Bitmap]::new($ws.w, $ws.h)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $g.Clear([System.Drawing.Color]::Transparent)
    
    $darkBlue = [System.Drawing.Color]::FromArgb(255, 10, 25, 55)
    $midBlue = [System.Drawing.Color]::FromArgb(255, 20, 60, 120)
    $teal = [System.Drawing.Color]::FromArgb(255, 0, 180, 160)
    $bgBrush = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
        [System.Drawing.Point]::new(0, 0),
        [System.Drawing.Point]::new($ws.w, $ws.h),
        $darkBlue, $teal)
    $g.FillRectangle($bgBrush, 0, 0, $ws.w, $ws.h)
    
    $iconSize = [int]($ws.h * 0.7)
    $iconX = [int]($ws.h * 0.15)
    $iconY = [int](($ws.h - $iconSize) / 2)
    
    $moonRadius = $iconSize / 2
    $cx = $iconX + $moonRadius
    $cy = $iconY + $moonRadius
    $moonOffset = $moonRadius * 0.15
    
    $moonRect = [System.Drawing.RectangleF]::new($cx - $moonRadius + $moonOffset, $cy - $moonRadius, $moonRadius * 2, $moonRadius * 2)
    $moonPath = [System.Drawing.Drawing2D.GraphicsPath]::new()
    $moonPath.AddEllipse($moonRect)
    $green = [System.Drawing.Color]::FromArgb(255, 0, 220, 140)
    $lightGreen = [System.Drawing.Color]::FromArgb(255, 100, 240, 180)
    $moonBrush = [System.Drawing.Drawing2D.PathGradientBrush]::new($moonPath)
    $moonBrush.CenterColor = $lightGreen
    $moonBrush.SurroundColors = @($teal)
    $g.FillEllipse($moonBrush, $moonRect)
    
    $cutoutRadius = $moonRadius * 0.85
    $cutoutOffset = $moonOffset + $moonRadius * 0.35
    $cutoutRect = [System.Drawing.RectangleF]::new($cx - $cutoutRadius + $cutoutOffset, $cy - $cutoutRadius, $cutoutRadius * 2, $cutoutRadius * 2)
    $g.FillEllipse([System.Drawing.SolidBrush]::new($darkBlue), $cutoutRect)
    
    $fontSize = [int]($ws.h * 0.22)
    $font = [System.Drawing.Font]::new("Segoe UI", $fontSize, [System.Drawing.FontStyle]::Bold)
    $textBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::White)
    $text = "Moonlight"
    $textSize = $g.MeasureString($text, $font)
    $textX = $iconX + $iconSize + $ws.w * 0.03
    $textY = ($ws.h - $textSize.Height) / 2
    $g.DrawString($text, $font, $textBrush, $textX, $textY)
    
    $bmp.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose()
    $bmp.Dispose()
    Write-Host "Created Wide: $outputPath ($($ws.w)x$($ws.h))"
}

# Splash screen (620x300 base)
$splashScales = @(
    @{ scale=100; w=620; h=300 },
    @{ scale=125; w=775; h=375 },
    @{ scale=150; w=930; h=450 },
    @{ scale=200; w=1240; h=600 },
    @{ scale=400; w=2480; h=1200 }
)

foreach ($ss in $splashScales) {
    $outputPath = "G:\moonlight-xbox-ipv6\Assets\SplashScreen.scale-$($ss.scale).png"
    
    $bmp = [System.Drawing.Bitmap]::new($ss.w, $ss.h)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.Clear([System.Drawing.Color]::Transparent)
    
    $darkBlue = [System.Drawing.Color]::FromArgb(255, 10, 25, 55)
    $midBlue = [System.Drawing.Color]::FromArgb(255, 20, 60, 120)
    $teal = [System.Drawing.Color]::FromArgb(255, 0, 180, 160)
    $bgBrush = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
        [System.Drawing.Point]::new(0, 0),
        [System.Drawing.Point]::new($ss.w, $ss.h),
        $darkBlue, $midBlue)
    $g.FillRectangle($bgBrush, 0, 0, $ss.w, $ss.h)
    
    $iconSize = [int]($ss.h * 0.5)
    $cx = $ss.w / 2
    $cy = $ss.h / 2 - $ss.h * 0.05
    $moonRadius = $iconSize / 2
    $moonOffset = $moonRadius * 0.15
    
    $moonRect = [System.Drawing.RectangleF]::new($cx - $moonRadius + $moonOffset, $cy - $moonRadius, $moonRadius * 2, $moonRadius * 2)
    $moonPath = [System.Drawing.Drawing2D.GraphicsPath]::new()
    $moonPath.AddEllipse($moonRect)
    $green = [System.Drawing.Color]::FromArgb(255, 0, 220, 140)
    $lightGreen = [System.Drawing.Color]::FromArgb(255, 100, 240, 180)
    $moonBrush = [System.Drawing.Drawing2D.PathGradientBrush]::new($moonPath)
    $moonBrush.CenterColor = $lightGreen
    $moonBrush.SurroundColors = @($teal)
    $g.FillEllipse($moonBrush, $moonRect)
    
    $cutoutRadius = $moonRadius * 0.85
    $cutoutOffset = $moonOffset + $moonRadius * 0.35
    $cutoutRect = [System.Drawing.RectangleF]::new($cx - $cutoutRadius + $cutoutOffset, $cy - $cutoutRadius, $cutoutRadius * 2, $cutoutRadius * 2)
    $g.FillEllipse([System.Drawing.SolidBrush]::new($darkBlue), $cutoutRect)
    
    $fontSize = [int]($ss.h * 0.12)
    $font = [System.Drawing.Font]::new("Segoe UI", $fontSize, [System.Drawing.FontStyle]::Bold)
    $textBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::White)
    $text = "Moonlight"
    $textSize = $g.MeasureString($text, $font)
    $textX = ($ss.w - $textSize.Width) / 2
    $textY = $cy + $moonRadius + $ss.h * 0.04
    $g.DrawString($text, $font, $textBrush, $textX, $textY)
    
    $bmp.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose()
    $bmp.Dispose()
    Write-Host "Created Splash: $outputPath ($($ss.w)x$($ss.h))"
}

# Also generate altform-unplated variants for Square44x44Logo
$altSizes = @(16, 24, 32, 48, 256)
foreach ($s in $altSizes) {
    $outputPath = "G:\moonlight-xbox-ipv6\Assets\Square44x44Logo.altform-unplated_targetsize-$s.png"
    CreateMoonlightIcon -size $s -outputPath $outputPath
    $outputPath = "G:\moonlight-xbox-ipv6\Assets\Square44x44Logo.altform-lightunplated_targetsize-$s.png"
    CreateMoonlightIcon -size $s -outputPath $outputPath
}

# targetsize variants
$targetSizes = @(16, 24, 32, 48, 256)
foreach ($s in $targetSizes) {
    $outputPath = "G:\moonlight-xbox-ipv6\Assets\Square44x44Logo.targetsize-$s.png"
    CreateMoonlightIcon -size $s -outputPath $outputPath
}

Write-Host "`nAll icons generated successfully with correct dimensions!"