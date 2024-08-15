$bookPath = $args[0]
$bookMarkPath = $args[1]

#ͨ������
$showLineCnt = 5        # ÿ����ʾ����
$showLineSize = 50      # ÿ����ʾ����

# �ļ���������ʾ���˳�
if( -not( Test-Path -Path $bookPath ) )
{
    Write-Host "�ļ�"$bookPath" ������"
    exit
}

# ��ǩ�����ڽ��д���
if( -not( Test-Path -Path $bookMarkPath ) )
{
    New-Item -Path $bookMarkPath -ItemType File -Force
    "0" | Set-Content -Path $bookMarkPath -Force
}

# ����ȫ���ļ�����
$content = Get-Content -Path $bookPath -Raw
$chunks = [System.Text.RegularExpressions.Regex]::Matches($content, ".{1,$showLineSize}")

# ��ȡ��ǩ���ٴ�д��ȷ����ǩ������ȷ
$mark = Get-Content $bookMarkPath -TotalCount 1
if( $mark -eq $null )
{
    $mark = 0
}
else
{
    $mark = [int]$mark.Split(' ')[0]
}
if( $mark -ge $chunks.Count )
{
    $mark = 0
}
$mark | Set-Content -Path $bookMarkPath -Force

# ��������ʾÿ����
$showCnt = 0                # ��������ʾ����
if( $mark -ge $showLineCnt )
{
    $showCnt -= $showLineCnt
}
$getCh = $false             # goto���߼����棬ֱ����ת����ȡ����
$curMark = 0

while( $true )
{
    if( $curMark -ge $chunks.Count )
    {
        Write-Host "----------- �������һҳ ------------"
    }
    else
    {
        # ��ǩǰ�����ݲ���ʾ
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
    # ��ʾ�����м�����ƴ���
    # $showCnt -gt 0 : ���ڷ�ҳ����ʾ֮ǰ��һЩ����
    if( ( $getCh -eq $true ) -or 
        ( ( $showCnt -gt 0 ) -and ( $showCnt % $showLineCnt -eq 0 ) ) -or
        ( $curMark -ge $chunks.Count ) )
    {
        $showCnt = 0
        $getCh = $false
        $ch = $Host.UI.RawUI.ReadKey()
        Write-Host "`r `r" -NoNewline       # ��������
        
        # ����c.���
        if( $ch.Character -eq 'c' )
        {
            Clear-Host
            $curMark = 0
            $mark = 0
            $mark | Set-Content -Path $bookMarkPath -Force
            continue
        }
        # �������
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
                Write-Host "δ�ҵ�" $findStr
                $getCh = $true
                continue
            }
        }
        # h �����ĵ�
        if( ( $ch.Character -eq 'h' ) )
        {
            Write-Host "-------------------------------------"
            Write-Host "c`t�����ǩ"
            Write-Host "f`t���ң���f��ֱ�Ӽ���������ݣ�"
            Write-Host "h`t�����ĵ�"
            Write-Host "�ո�`t�����ǰ��Ļ"
            Write-Host "��ҳ���� �������� wsad Enter"
            Write-Host "-------------------------------------"
            $getCh = $true
            continue
        }
        # ����س�����
        # 13 ENTER
        # 40 DOWN
        if( ( $ch.VirtualKeyCode -eq 13 ) -or
            ( $ch.VirtualKeyCode -eq 40 ) -or 
            ( $ch.Character -eq 's' ) )
        {
            continue
        }
        # �Ϸ�ҳ   ��ҳ    �ҷ�ҳ
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
            # ��ҳʱ����ʾ֮ǰ��һЩ����
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
            $mark | Set-Content -Path $bookMarkPath -Force
            continue
        }
        # �ո�� ���ݿ������
        if( ( $ch.Character -eq ' ' ) )
        {
            Clear-Host
            $getCh = $true
            continue
        }
        Clear-Host
        $curMark - $showLineCnt | Set-Content -Path $bookMarkPath -Force
        exit
    }
}
exit
