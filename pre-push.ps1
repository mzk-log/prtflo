# pre-push.ps1

Write-Host "=== pre-push.ps1: スクリプトが実行されました ==="

# リポジトリのルートパスを取得
$repoRoot = git rev-parse --show-toplevel
$gitignorePath = Join-Path $repoRoot "gitignore.txt"

Write-Host "=== pre-push.ps1:repoRootです ===> $repoRoot"
Write-Host "=== pre-push.ps1:gitignorePathです ===> $gitignorePath"

if (-Not (Test-Path $gitignorePath)) {
    exit 0
}

# gitignore.txtの各行を取得（空行やコメントは除外）
$patterns = Get-Content $gitignorePath | Where-Object { $_ -and -not ($_.Trim().StartsWith("#")) }

# push対象のファイル一覧を取得
## $pushFiles = git diff --cached --name-only
$pushFiles = git diff --name-only origin/main...HEAD

Write-Host "push対象ファイル一覧:"
$pushFiles | ForEach-Object { Write-Host $_ }

# 除外ファイルリスト
$unstagedFiles = @()

foreach ($file in $pushFiles) {
    foreach ($pattern in $patterns) {
        $pattern = $pattern.Trim()
        if ($pattern -eq "") { continue }

        # ディレクトリ除外
        if ($pattern.EndsWith("/")) {
            if ($file -like "$pattern*") {
                $unstagedFiles += $file
                break
            }
        }
        # 拡張子除外
        elseif ($pattern.StartsWith("*.")) {
            $ext = $pattern.Substring(1) # 例: .txt
            if ($file.ToLower().EndsWith($ext.ToLower())) {
                $unstagedFiles += $file
                break
            }
        }
        # その他（今回は不要だが念のため）
        else {
            if ($file -eq $pattern) {
                $unstagedFiles += $file
                break
            }
        }
    }
}

if ($unstagedFiles.Count -gt 0) {
    Write-Host "以下のファイルは除外パターンに該当するため、push対象から外します:"
    $unstagedFiles | ForEach-Object { Write-Host $_ }
    git reset HEAD -- $unstagedFiles
    Write-Host "除外ファイルをステージング解除しました。再度pushを実行してください。"
    exit 1
}

exit 0
