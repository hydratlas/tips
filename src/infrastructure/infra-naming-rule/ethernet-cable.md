# イーサネットケーブルの命名規則

データセンターやサーバールームでのイーサネットケーブルの命名規則です。ケーブルの識別と管理を効率化し、トラブルシューティングを迅速に行えるようにします。

## 形式
[命名年月]-[固有番号]-[長さ]-[コネクターおよびケーブル種類]

## 例
- 202406-01-0.5m-CAT5E
- 202406-02-1.5m-SFP+-PDAC

## 命名年月
購入または使用開始の年月をYYYYMM形式で記載する。

- 例:
  - 202406

## 固有番号
命名年月において重複しない番号を記載する。ゼロ埋めありの2桁を基本とするが、必要に応じて3桁以上にすることができる。

## 長さ
ケーブルの長さをメートル単位で記載して、末尾に単位の`m`を付す。必要に応じて小数点以下も記載する。

- 例:
  - 0.5m
  - 1m
  - 1.5m
  - 10m

## コネクターおよびケーブル種類
コネクターおよびケーブルの種類を以下の規則に沿って記載する。ゼロ埋めした2桁を基本として、必要に応じて3桁以上にすることもできる。

### 銅線イーサネットケーブル
コネクターはほとんどRJ45のため、ケーブルの種類だけを記載する。

- Category 5e: CAT5E
- Category 6: CAT6
- Category 6a: CAT6A

### DACケーブル・AOCケーブル
コネクターの種類とケーブルの種類を記載する。

- 形式
  - コネクターの種類が両端で同じ場合: [コネクター種類]-[ケーブル種類]
  - コネクターの種類が両端で異なる場合: [コネクター種類]-[コネクター種類]-[ケーブル種類]
- コネクター種類
  - SFP
  - SFP+
  - SFP28
  - QSFP
  - QSFP+
  - QSFP28
- ケーブル種類
  - パッシブDACケーブル: PDAC
  - アクティブDACケーブル: ADAC
  - AOCケーブル: AOC
- 例:
  - SFP+-PDAC

### 光ファイバーケーブル
コネクターの種類とケーブルの種類を記載する。

- 形式
  - コネクターの種類が両端で同じ場合: [コネクター種類]-[ケーブル種類]
  - コネクターの種類が両端で異なる場合: [コネクター種類]-[コネクター種類]-[ケーブル種類]
- コネクター種類
  - SC
  - LC
- ケーブル種類
  - シングルモードファイバー (SMF)
    - OS1
    - OS2
  - マルチモードファイバー (MMF)
    - OM1
    - OM2
    - OM3
    - OM4
    - OM5
- 例:
  - LC-OM2
