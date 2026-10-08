param([switch]$Force)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$root = Split-Path $PSScriptRoot -Parent
$artRoot = Join-Path $root 'art/inner_circle/v1'
$assetRoot = Join-Path $root 'mod/heart_of_iron/gfx/interface/hof_ic'
$sourceRoot = Join-Path $artRoot 'source'
$pngRoot = Join-Path $artRoot 'png'
foreach ($dir in @($assetRoot, $sourceRoot, $pngRoot)) {
    [System.IO.Directory]::CreateDirectory($dir) | Out-Null
}
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.IO;
using System.Drawing;
using System.Drawing.Imaging;
using System.Drawing.Drawing2D;
public static class HofArtExport {
    // Mechanical sprite export only: remove unused canvas, resample, encode.
    public static string Export(string source, string png, string dds, int w, int h, bool trim, bool light) {
        using (var src = new Bitmap(source)) {
            int l=src.Width, t=src.Height, r=-1, b=-1;
            if(trim) {
                for(int y=0;y<src.Height;y++) for(int x=0;x<src.Width;x++) {
                    if(src.GetPixel(x,y).A>8) { l=Math.Min(l,x);t=Math.Min(t,y);r=Math.Max(r,x);b=Math.Max(b,y); }
                }
                if(r<l) throw new Exception("Empty source: "+source);
                l=Math.Max(0,l-2);t=Math.Max(0,t-2);r=Math.Min(src.Width-1,r+2);b=Math.Min(src.Height-1,b+2);
            } else { l=0;t=0;r=src.Width-1;b=src.Height-1; }
            using(var dst=new Bitmap(w,h,PixelFormat.Format32bppArgb)) {
                using(var g=Graphics.FromImage(dst)) {
                    g.CompositingMode=CompositingMode.SourceCopy;
                    g.InterpolationMode=InterpolationMode.HighQualityBicubic;
                    g.PixelOffsetMode=PixelOffsetMode.HighQuality;
                    using(var attrs=new ImageAttributes()) {
                        attrs.SetWrapMode(WrapMode.TileFlipXY);
                        g.DrawImage(src,new Rectangle(0,0,w,h),l,t,r-l+1,b-t+1,GraphicsUnit.Pixel,attrs);
                    }
                }
                // Normalize overlay opacity to a production ceiling of 18%.
                // Keep generated relative alpha and RGB; no painted content is added.
                if(light) {
                    int max=0;
                    for(int y=0;y<h;y++) for(int x=0;x<w;x++) max=Math.Max(max,dst.GetPixel(x,y).A);
                    if(max>46) for(int y=0;y<h;y++) for(int x=0;x<w;x++) {
                        var c=dst.GetPixel(x,y);dst.SetPixel(x,y,Color.FromArgb((int)Math.Round(c.A*46.0/max),c.R,c.G,c.B));
                    }
                }
                dst.Save(png,ImageFormat.Png);
                using(var bw=new BinaryWriter(File.Create(dds))) {
                    bw.Write(0x20534444u);bw.Write(124u);bw.Write(0x100Fu);
                    bw.Write((uint)h);bw.Write((uint)w);bw.Write((uint)(w*4));bw.Write(0u);bw.Write(0u);
                    for(int i=0;i<11;i++) bw.Write(0u);
                    bw.Write(32u);bw.Write(0x41u);bw.Write(0u);bw.Write(32u);
                    bw.Write(0x00ff0000u);bw.Write(0x0000ff00u);bw.Write(0x000000ffu);bw.Write(0xff000000u);
                    bw.Write(0x1000u);for(int i=0;i<4;i++) bw.Write(0u);
                    for(int y=0;y<h;y++) for(int x=0;x<w;x++) {
                        var c=dst.GetPixel(x,y);bw.Write(c.B);bw.Write(c.G);bw.Write(c.R);bw.Write(c.A);
                    }
                }
                int zero=0, partial=0, maxAlpha=0;
                for(int y=0;y<h;y++) for(int x=0;x<w;x++) {
                    int a=dst.GetPixel(x,y).A;
                    if(a==0) zero++;else if(a<255) partial++;
                    maxAlpha=Math.Max(maxAlpha,a);
                }
                if(zero==0) throw new Exception("No transparency: "+png);
                return String.Format("{0}x{1}; alpha0={2}; partial={3}; maxAlpha={4}; crop={5},{6},{7},{8}",w,h,zero,partial,maxAlpha,l,t,r-l+1,b-t+1);
            }
        }
    }
}
'@
$manifest = Get-Content -LiteralPath (Join-Path $artRoot 'manifest.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$report = @('Built-in image_gen; PNG + uncompressed BGRA8 DDS; no mipmaps.')
foreach ($asset in $manifest.assets) {
    $source = Join-Path $sourceRoot ($asset.name + '.png')
    if (-not (Test-Path -LiteralPath $source)) { Copy-Item -LiteralPath $asset.source -Destination $source }
    $png = Join-Path $pngRoot ($asset.name + '.png')
    $dds = Join-Path $assetRoot ($asset.name + '.dds')
    if (-not $Force -and ((Test-Path -LiteralPath $png) -or (Test-Path -LiteralPath $dds))) {
        throw "Output exists; use -Force explicitly to rebuild: $($asset.name)"
    }
    $light = $asset.name -eq 'hof_ic_spotlight'
    $trim = $asset.name -match 'ribbon|title_box|name_box|trait_box'
    $result = [HofArtExport]::Export($source,$png,$dds,$asset.size[0],$asset.size[1],$trim,$light)
    $report += "$($asset.name): $result"
}
$report | Set-Content -LiteralPath (Join-Path $artRoot 'export-report.txt') -Encoding UTF8
$report
