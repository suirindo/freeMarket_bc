//会員登録する関数
function registerAccount() {
    //テキストボックスから入力内容を取得する
    var userName = document.getElementById("userName").value;
    var userEmail = document.getElementById("userEmail").value;

    //コントラクトの呼び出し
    return contract.methods.registerAccount(userName, userEmail).send({from: coinbase });
}
