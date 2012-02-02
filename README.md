# md2xyref - Markdown to xyzzy Reference

## DESCRIPTION

Markdown 形式で書いたリファレンスを xyzzy のリファレンス (XML) に変換するスクリプト。
Ruby 1.9 が必要です。

## USAGE

```
> ruby md2xyref.rb reference/foo.md site-lisp > reference/foo.xml
```


## REFERENCE

Markdown でのリファレンスは以下のように記述する。

```
### Package: md2xyref.sample

md2xyref のサンプルパッケージです。


### Function: add X Y

X と Y を足した結果を返します。

__See Also:__

  * sub

### Function: sub X Y

X から Y を引いた結果を返します。

__See Also:__

  * add
```

具体的なサンプルは <https://raw.github.com/miyamuko/http-client/master/reference/http-client.md> を参照。
