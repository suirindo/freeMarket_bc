// 出品する関数
function sell() {
    // テキストボックスから入力内容を取得する
    var itemName = document.getElementById("itemName").value;
    var description = document.getElementById("description").value;
    var price = document.getElementById("price").value;
    var googleDocID = document.getElementById("googleDocID").value;
    var IPFSHash = "";

    // コントラクトの呼び出し
    return contract.methods.sell(itemName, description, price, googleDocID, IPFSHash).send({ from: coinbase });
}
