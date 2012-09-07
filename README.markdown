# Uduki 

markdownで記述する日々のメモ帳です。日付が代わると自動的に最新へ書き換わります。
何かメモしておきたいけどファイル名つけるのも面倒だしBlogに書くほどでもない。
もしくは、公に書けないけどメモっておきたい等の目的に適しております。

# TODO 

+ ストレージ変更可能へ
+ 検索機能

# 使用方法 

## mysql

    git clone git://github.com/hiroyukim/Uduki.git
    cd Uduki
    cat sql/mysql.sql | mysql -uroot -p
    plackup 


# 全文検索エンジンへの対応

全文検索エンジンを入れなくても検索ができるようにしてありますがパフォーマンスを考えると
mroongaなどをinstallすることをおすすめします。installしたらconfigのfull_text_searchを1へ
変更してください。

## mroonga

基本MySQLに対応した全文検索エンジンなら蕩くと思いますがmroongaがお勧めです。

<http://mroonga.github.com/ja/>

こちらのinstallガイドにしたがってmroongaを入れてください。

http://mroonga.github.com/ja/docs/install.html

## config/*.pl

    full_text_search => 1

# Author

    Hiroyuki Yamanaka

# ライセンス

Copyright (C) 2011 HIROYUKI Yamanaka <hiroyukimm 空気読んで gmail 空気読んで com>

Released under the [MIT license](http://creativecommons.org/licenses/MIT/).
