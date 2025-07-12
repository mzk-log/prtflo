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
$pushFiles = git diff --cached --name-only

Write-Host "push対象ファイル一覧:"
$pushFiles | ForEach-Object { Write-Host $_ }

foreach ($file in $pushFiles) {
    foreach ($pattern in $patterns) {
        $pattern = $pattern.Trim()
        if ($pattern -eq "") { continue }

        # ディレクトリ除外
        if ($pattern.EndsWith("/")) {
            if ($file -like "$pattern*") {
                Write-Host "push対象にgitignore.txtで除外指定されたディレクトリ配下のファイルが含まれています: $file"
                Write-Host "pushを中止します。"
                exit 1
            }
        }
        # 拡張子除外
        elseif ($pattern.StartsWith("*.")) {
            $ext = $pattern.Substring(1) # 例: .txt
            if ($file.ToLower().EndsWith($ext.ToLower())) {
                Write-Host "push対象にgitignore.txtで除外指定された拡張子のファイルが含まれています: $file"
                Write-Host "pushを中止します。"
                exit 1
            }
        }
        # その他（今回は不要だが念のため）
        else {
            if ($file -eq $pattern) {
                Write-Host "push対象にgitignore.txtで除外指定されたファイルが含まれています: $file"
                Write-Host "pushを中止します。"
                exit 1
            }
        }
    }
}

exit 0
