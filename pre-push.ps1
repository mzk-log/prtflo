# pre-push.ps1

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

foreach ($pattern in $patterns) {
    # ワイルドカードやディレクトリ指定に対応
    $regex = [Regex]::Escape($pattern).Replace("\*", ".*").Replace("\?", ".")
    foreach ($file in $pushFiles) {
        if ($file -match "^$regex($|/)" ) {
            Write-Host "push対象にgitignore.txtで除外指定されたファイル/フォルダが含まれています: $file"
            Write-Host "pushを中止します。"
            exit 1
        }
    }
}

exit 0
