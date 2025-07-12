# pre-push.ps1

Write-Host "=== pre-push.ps1: スクリプトが実行されました ==="

# リポジトリのルートパスを取得
$repoRoot = git rev-parse --show-toplevel
$gitignorePath = Join-Path $repoRoot "gitignore.txt"

if (-Not (Test-Path $gitignorePath)) {
    exit 0
}

# gitignore.txtの各行を取得（空行やコメントは除外）
$patterns = Get-Content $gitignorePath | Where-Object { $_ -and -not ($_.Trim().StartsWith("#")) }

# push対象のファイル一覧を取得
$pushFiles = git diff --cached --name-only

Write-Host "push対象ファイル一覧:"
$pushFiles | ForEach-Object { Write-Host $_ }

foreach ($pattern in $patterns) {
    $pattern = $pattern.Trim()
    if ($pattern -eq "") { continue }
    if ($pattern.EndsWith("/")) {
        # ディレクトリの場合
        $regex = "^" + [Regex]::Escape($pattern)
    } elseif ($pattern.StartsWith("*.")) {
        # 拡張子の場合
        $ext = $pattern.Substring(1) # 例: .txt
        $regex = [Regex]::Escape($ext) + "$"
    } else {
        # その他
        $regex = "^" + [Regex]::Escape($pattern) + "$"
    }
    foreach ($file in $pushFiles) {
        if ($file -match $regex) {
            Write-Host "push対象にgitignore.txtで除外指定されたファイル/フォルダが含まれています: $file"
            Write-Host "pushを中止します。"
            exit 1
        }
    }
}

exit 0
