# リリース手順

## 1. バージョン決定

`vX.Y.Z` のタグを使う。

## 2. Release ビルド

```bash
xcodebuild -project MacSystemMonitor.xcodeproj \
  -scheme MacSystemMonitor \
  -configuration Release \
  -derivedDataPath build build
```

## 3. zip 作成・SHA256 取得

```bash
ditto -c -k --keepParent build/Build/Products/Release/Peekr.app /tmp/Peekr_vX.Y.Z.zip
shasum -a 256 /tmp/Peekr_vX.Y.Z.zip
```

## 4. GitHub Release 作成

```bash
gh release create vX.Y.Z /tmp/Peekr_vX.Y.Z.zip \
  --repo kazuhitogo/mac-peekr \
  --title "vX.Y.Z" \
  --notes-file /tmp/release_notes.md
```

## 5. homebrew-tap の Cask 更新

`kazuhitogo/homebrew-tap` の `Casks/peekr.rb` を更新:

```ruby
cask "peekr" do
  version "X.Y.Z"
  sha256 "ここに shasum の結果"

  url "https://github.com/kazuhitogo/mac-peekr/releases/download/v#{version}/Peekr_v#{version}.zip"
  name "Peekr"
  desc "macOS system monitor floating widget"
  homepage "https://github.com/kazuhitogo/mac-peekr"

  depends_on macos: ">= :sequoia"

  app "Peekr.app"
end
```

GitHub API で更新（大きなファイルは git 経由）:
```bash
ENCODED=$(base64 < /tmp/peekr.rb)
gh api repos/kazuhitogo/homebrew-tap/contents/Casks/peekr.rb \
  --method PUT \
  --field message="chore: bump Peekr to vX.Y.Z" \
  --field content="$ENCODED" \
  --field sha="現在のファイルSHA" \
  --jq '.commit.sha'
```

現在の SHA 取得:
```bash
gh api repos/kazuhitogo/homebrew-tap/contents/Casks/peekr.rb --jq '.sha'
```

## 注意

- `brew install` を含むコマンドはシェルの hook に拒否されることがある → temp ファイル経由で回避
- 画像など大きいバイナリは GitHub API（base64）ではなく git で push する
