# jplint

Claude Code 用の日本語テキスト校正プラグイン。textlint をベースに、日本語文書の品質チェックと自動修正を行う。

## ルール構成

- **[textlint-rule-preset-japanese](https://github.com/textlint-ja/textlint-rule-preset-japanese)** - 日本語の基本的な文法チェック（二重否定、ら抜き言葉、助詞の連続等）
- **[textlint-rule-preset-jtf-style](https://github.com/textlint-ja/textlint-rule-preset-jtf-style)** - JTF日本語標準スタイルガイドに基づく表記チェック（選択的に有効化）
- **[textlint-rule-prh](https://github.com/textlint-rule/textlint-rule-prh)** - 辞書ベースの校正（ひらく漢字、誤字、重言、外来語表記等）
- **[textlint-rule-ja-no-redundant-expression](https://github.com/textlint-ja/textlint-rule-ja-no-redundant-expression)** - 冗長な表現の検出
- **[textlint-rule-ja-no-abusage](https://github.com/textlint-ja/textlint-rule-ja-no-abusage)** - 技術文書の誤用検出
- **[textlint-rule-no-hankaku-kana](https://github.com/textlint-rule/textlint-rule-no-hankaku-kana)** - 半角カナの検出
- **[textlint-rule-ja-no-successive-word](https://github.com/textlint-ja/textlint-rule-ja-no-successive-word)** - 同一単語の連続（タイポ検出）

## 使い方

```
/jplint path/to/file.md
/jplint path/to/directory
/jplint                     # git で変更されたファイルを自動検出
```

## Acknowledgements

prh 辞書は [テキスト校正くん](https://github.com/ics-creative/project-japanese-proofreading)（ICS INC.）の [textlint-rule-preset-icsmedia](https://github.com/ics-creative/textlint-rule-preset-icsmedia) をベースにしています。
