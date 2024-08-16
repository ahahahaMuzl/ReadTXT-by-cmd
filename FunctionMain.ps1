$bookPath = $args[0]
$bookName = [System.IO.Path]::GetFileNameWithoutExtension( $bookPath )
$bookmarkFolderPath = "$PSScriptRoot\bookmark"
$bookmarkPath = "$bookmarkFolderPath\$bookName.bookmark"

# 通用配置
$showLineCnt = 5                        # 每次显示行数
$showLineSize = 50                      # 每次显示字数
$clearBookmarkWhenReadFinish = $true    # 完成阅读后清除书签内容

# 文件不存在提示并退出
if( -not( Test-Path -Path $bookPath ) )
{
    Write-Host "文件"$bookPath" 不存在"
    exit
}

# 创建书签文件夹
if( -not( Test-Path -Path $bookmarkFolderPath ) )
{
    New-Item -Path $bookmarkFolderPath -ItemType Directory -Force
}

# 书签不存在进行创建
if( -not( Test-Path -Path $bookmarkPath ) )
{
    New-Item -Path $bookmarkPath -ItemType File -Force
    "0" | Set-Content -Path $bookmarkPath -Force
}

# 加载全部文件内容
$content = Get-Content -Path $bookPath -Raw
$chunks = [System.Text.RegularExpressions.Regex]::Matches( $content, ".{1,$showLineSize}" )

# 获取书签并再次写入确保书签内容正确
$mark = Get-Content $bookmarkPath -TotalCount 1
if( $mark -eq $null )
{
    $mark = 0
}
else
{
    $mark = [int]$mark.Split( ' ' )[0]
}
if( $mark -ge $chunks.Count )
{
    $mark = 0
}
$mark | Set-Content -Path $bookmarkPath -Force

# 遍历并显示每个块
$showCnt = 0                # 当次已显示行数
if( $mark -ge $showLineCnt )
{
    $showCnt -= $showLineCnt
}
$getCh = $false             # goto的逻辑代替，直接跳转至获取键入
$curMark = 0

while( $true )
{
    if( $curMark -ge $chunks.Count )
    {
        Write-Host "----------- 已至最后一页 ------------"
        if( $clearBookmarkWhenReadFinish -eq $true )
        {
            0 | Set-Content -Path $bookmarkPath -Force
        }
    }
    else
    {
        # 书签前的内容不显示
        if( $getCh -eq $false )
        {
            if( $curMark -lt $mark - $showLineCnt )
            {
                $curMark += 1
                continue
            }
            Write-Host $chunks[$curMark].Value
            $curMark += 1
            $showCnt += 1
        }
        if( $curMark -ge $chunks.Count )
        {
            continue
        }
    }
    # 显示完后进行键入控制处理
    # $showCnt -gt 0 : 用于翻页多显示之前的一些内容
    if( ( $getCh -eq $true ) -or 
        ( ( $showCnt -gt 0 ) -and ( $showCnt % $showLineCnt -eq 0 ) ) -or
        ( $curMark -ge $chunks.Count ) )
    {
        $showCnt = 0
        $getCh = $false
        $ch = $Host.UI.RawUI.ReadKey()
        Write-Host "`r `r" -NoNewline       # 擦除输入
        
        # 处理c.清除
        if( $ch.Character -eq 'c' )
        {
            Clear-Host
            $curMark = 0
            $mark = 0
            $mark | Set-Content -Path $bookmarkPath -Force
            continue
        }
        # 处理查找
        if( $ch.Character -eq 'f' )
        {
            Write-Host "f " -NoNewline
            $findStr = Read-Host
            $find = $false

            for( $i = 0; $i -lt $chunks.Count; $i += 1 )
            {
                if( $chunks[ ( $curMark - 1 + $i ) % $chunks.Count ].Value -match $findStr )
                {
                    $find = $true
                    break
                }
            }
            if( $find -eq $true )
            {
                $showCnt = 0
                $curMark = ( $curMark - 1 + $i ) % $chunks.Count
                continue
            }
            else
            {
                Write-Host "未找到" $findStr
                $getCh = $true
                continue
            }
        }
        # h 帮助文档
        if( ( $ch.Character -eq 'h' ) )
        {
            Write-Host "-------------------------------------"
            Write-Host "c`t清除书签"
            Write-Host "f`t查找（按f后直接键入查找内容）"
            Write-Host "h`t帮助文档"
            Write-Host "空格`t清除当前屏幕"
            Write-Host "翻页控制 ↑↓←→ wsad Enter"
            Write-Host "-------------------------------------"
            $getCh = $true
            continue
        }
        # 处理回车继续
        # 13 ENTER
        # 40 DOWN
        if( ( $ch.VirtualKeyCode -eq 13 ) -or
            ( $ch.VirtualKeyCode -eq 40 ) -or 
            ( $ch.Character -eq 's' ) )
        {
            continue
        }
        # 上翻页   左翻页    右翻页
        # 38 UP  37 LEFT  39 RIGHT
        #  'w'     'a'      'd'
        if( ( $ch.VirtualKeyCode -eq 38 ) -or
            ( $ch.VirtualKeyCode -eq 37 ) -or
            ( $ch.VirtualKeyCode -eq 39 ) -or
            ( $ch.Character -eq 'w' ) -or
            ( $ch.Character -eq 'a' ) -or
            ( $ch.Character -eq 'd' ) )
        {
            Clear-Host
            $curMark = $curMark - $showLineCnt
            $offset = 0
            if( ( $ch.VirtualKeyCode -eq 38 ) -or ( $ch.Character -eq 'w' ) )
            {
                $offset = - $showLineCnt
            }
            if( ( $ch.VirtualKeyCode -eq 37 ) -or ( $ch.Character -eq 'a' ) )
            {
                $offset = - 5 * $showLineCnt
            }
            if( ( $ch.VirtualKeyCode -eq 39 ) -or ( $ch.Character -eq 'd' ) )
            {
                $offset = 5 * $showLineCnt
            }
            $curMark += $offset
            # 翻页时多显示之前的一些内容
            $curMark -= $showLineCnt
            $showCnt -= $showLineCnt
            if( $curMark -lt 0 )
            {
                $curMark = 0
                $showCnt = 0
            }
            if( $curMark -ge $chunks.Count )
            {
                $curMark = $chunks.Count - 1
            }

            $mark = $curMark
            $mark | Set-Content -Path $bookmarkPath -Force
            continue
        }
        # 空格键 内容快速清除
        if( ( $ch.Character -eq ' ' ) )
        {
            Clear-Host
            $getCh = $true
            continue
        }
        Clear-Host
        $curMark - $showLineCnt | Set-Content -Path $bookmarkPath -Force
        exit
    }
}
exit
