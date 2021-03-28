/*
account.jsではブロックチェーンからアドレス毎に会員情報を
記録したデータ構造体であるaccountsを取得しています。
*/


//会員情報を表示する
var keyList = ["名前","Eメールアドレス","取引回数","評価","出品回数","購入回数"];
var idxList = [0, 1, 2, 3, 4, 5]; //keyに対応するインデックス

function showAccount(){
    //テキストボックスから入力内容を取得する
    var address = document.getElementsById("address").value;

    contract.methods.accounts(address).call()
      // accountにはaccounts（address)が代入される
      .then(function(account) {
          //会員情報をDOMに追加する
          for(var i = 0; i < idxList.length; i++) {
              var elem = document.createElement("p");
              elem.textContent = keyList[i] + ":" + account[idxList[i]];
              document.getElementsById("account").appendChild(elem);
          }
      });
}
