var _numItems; // 出品されている商品数
var col = 3;   // 商品一覧を表示する際の列数

// 1.出品されている商品数を取得する
contract.methods.numItems().call()
.then(function(numItems) {
    _numItems = numItems;
    
// 2.商品情報を表示するDOMや取引を進めるためのボタンを配置する。
}).then(function() {
    var rows = [];
    var table = document.getElementById("table"); // bodyのテーブル要素を取得する
    var row = Math.ceil(_numItems / col); // 商品を表示する際の行数
    var idx = 0; // 商品番号

    // 取引を進めるボタンのIDとボタンに表示するテキスト
    var buttonId = ["buy", "ship", "receive", "sellerEvaluate", "buyerEvaluate"];
    var buttonText = ["この商品を購入", "発送完了通知", "受取完了通知", "出品者を評価", "購入者を評価"];

    // 商品の数だけテーブルにセルを追加する
    for (i = 0; i < row; i++) {
        rows.push(table.insertRow(-1)); // 行の追加
        for (j = 0; j < col; j++) {
            cell = rows[i].insertCell(-1); // 列の追加

            // DOMを作成する
            // idx：商品番号
            if (idx < _numItems) {
                var image = document.createElement("div");       // 商品画像を表示する
                var description = document.createElement("div"); // 商品説明を表示する
                var state = document.createElement("div");       // 取引の状態を表示する
                var button = document.createElement("div");      // 取引を進めるボタンを表示する
                
                // IDを指定する
                image.id = "image" + idx;
                description.id = "description" + idx;
                state.id = "state" + idx;
                button.id = "button" + idx;

                // 画像のみセンター揃え
                image.style.textAlign = "center";

                // 取引を進めるボタンを作成する
                for (k = 0; k < buttonId.length; k++) {
                    var p = document.createElement("p");
                    var btn = document.createElement("button");
                    btn.setAttribute("class", "btn btn-default");
                    btn.id = buttonId[k] + idx;
                    btn.textContent = buttonText[k];
                    p.appendChild(btn);
                    button.appendChild(p);
                }

                // 評価を選択するセレクトフォームを作成する
                var p = document.createElement("p");
                var form = document.createElement("div");
                form.setAttribute("class", "form-group");
                var label = document.createElement("label");
                label.textContent = "出品者または購入者の評価を選択して下さい";
                label.setAttribute("for", "value" + idx);
                var select = document.createElement("select");
                select.setAttribute("multiple", "");
                select.setAttribute("class", "form-control");
                select.id = "value" + idx;
                for(value = -2; value <= 2; value++) {
                    var option = document.createElement("option");
                    option.textContent = value;
                    option.value = value;
                    select.appendChild(option);
                }
                form.appendChild(label);
                form.appendChild(select);
                p.appendChild(form);
                button.appendChild(p);

                // セルにDOMを追加する
                cell.appendChild(image);
                cell.appendChild(description);
                cell.appendChild(state);
                cell.appendChild(button);

                idx++; // 商品番号の更新
            }
        }
    }
    
// 3.DOMに商品情報を入れる。ボタンに関数を登録する。
}).then(function() {
    for (idx = 0; idx < _numItems; idx++) {
        showImage(idx);       // 商品画像
        showDescription(idx); // 商品説明
        showState(idx);       // 取引状態
        setButton(idx);       // 取引を進めるボタンに関数を登録する
    }
});

// 商品画像を表示する
function showImage(idx) {
    contract.methods.images(idx).call().then(function(image) {
        // imageUrl = "https://ipfs.io/ipfs/" + image.ipfsHash; // ipfsを使用する場合
        imageUrl = "http://drive.google.com/uc?export=view&id=" + image.googleDocID; // googleDriveを使用する場合
        
        // 生成する要素と属性
        var image = document.createElement("img");
        image.id = "googleDriveImage" + idx;
        image.src = imageUrl;
        image.alt = "googleDriveImage" + idx;

        // 画像の読込みを待ってから画像をリサイズする
        image.addEventListener("load", function() {
            // 画像のサイズを取得する
            var orgWidth  = image.width;
            var orgHeight = image.height;

            image.height = 180; // 縦幅をリサイズ
            image.width = orgWidth * (image.height / orgHeight); // 高さを横幅の変化割合に合わせる
            image.style.borderRadius = "10px";

            // DOMに画像を入れる
            document.getElementById("image" + idx).appendChild(image);
        });
    });
}

// 商品情報を表示する
function showDescription(idx) {
    itemKeyList = ["商品名", "価格(wei)", "商品説明", "出品状態", "出品者", "出品者のアドレス", "購入者のアドレス"];
    itemIdxList = [3, 5, 4, 11, 2, 0, 1]; // keyに対応するインデックス

    contract.methods.items(idx).call().then(function(item) {
        for (var i = 0; i < itemIdxList.length; i++) {
            var elem = document.createElement("p");
            // 出品状態のみ，true⇒売切れ，false⇒出品中に表示を変更する
            if (i == 3) {
                if (item[itemIdxList[i]] == true) {
                    elem.textContent = itemKeyList[i] + " : 売切れ";
                } else {
                    elem.textContent = itemKeyList[i] + " : 出品中";
                }
            } else {
                elem.textContent = itemKeyList[i] + " : " + item[itemIdxList[i]];
            }
            document.getElementById("description" + idx).appendChild(elem);
        }
    });
}

// 取引の状態を表示する
function showState(idx) {
    stateKeyList = ["支払い", "発送", "受取", "出品者評価", "購入者評価"];
    stateIdxList = [6, 7, 8, 9, 10]; // keyに対応するインデックス

    contract.methods.items(idx).call().then(function(item) {
        for (var i = 0; i < stateIdxList.length; i++) {
            var elem = document.createElement("p");
            if (item[stateIdxList[i]] == true) {
                elem.textContent = stateKeyList[i] + " : 済み";
            } else {
                elem.textContent = stateKeyList[i] + " : 完了していません";
            }
            document.getElementById("state" + idx).appendChild(elem);
        }
    });
}

// 取引を進めるボタンに関数を登録する
function setButton(idx) {
    var price;
    contract.methods.items(idx).call().then(function(item) {
        price = item[5]; // 商品価格を取得する
    
    }).then(function() {
        document.getElementById("buy" + idx).setAttribute("onclick", "buy(" + idx + "," + price + ");");
        document.getElementById("ship" + idx).setAttribute("onclick", "ship(" + idx + ");");
        document.getElementById("receive" + idx).setAttribute("onclick", "receive(" + idx + ");");
        document.getElementById("sellerEvaluate" + idx).setAttribute("onclick", "sellerEvaluate(" + idx + ");");
        document.getElementById("buyerEvaluate" + idx).setAttribute("onclick", "buyerEvaluate(" + idx + ");");
    });
}

// 購入する関数
function buy(idx, price) {
    return contract.methods.buy(idx).send({ from: coinbase, value: price })
}

// 受取連絡する関数
function receive(idx) {
    return contract.methods.receive(idx).send({ from: coinbase })
}

// 発送連絡する関数
function ship(idx) {
    return contract.methods.ship(idx).send({ from: coinbase })
}

// 購入者を評価する関数
function buyerEvaluate(idx) {
    var buyerValue = document.getElementById("value" + idx).value;

    return contract.methods.buyerEvaluate(idx, buyerValue).send({ from: coinbase })
}

// 出品者を評価する関数
function sellerEvaluate(idx) {
    var sellerValue = document.getElementById("value" + idx).value;

    return contract.methods.sellerEvaluate(idx, sellerValue).send({ from: coinbase })
}
