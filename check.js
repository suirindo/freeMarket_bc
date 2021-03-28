/*
メタマスクがインストールされているかチェックする
メタマスクがインストールされている場合は，ウェブページを開いたときに，web3というグローバル変数にWeb3オブジェクトが自動的に代入されます。
メタマスクがインストールされていない場合，web3はundefinedとなります。
*/

if(typeof web3 !== "undefined") {
    web3js = new Web3(web3.currentProvider);
} else {
    alert("MetaMaskをインストールしてください。");
}

//メタマスクのアドレスを取得する
web3js.eth.getAccounts(function(err, accounts) {
    coinbase = accounts[0];
    console.log("coinbase is" + coinbase);
    if(typeof coinbase === "undefined") {
        alert("MetaMaskを起動してください。")
    }
});

//スマコンのアドレスを指定する
//自分がデプロイしたスマコンのアドレス
const address = "0x0AC3133A8CB0C6C751Fb6B2600ce4cFd81Eee0b9";

//スマコンのインスタンスを生成する
contract = new web3js.eth.Contract(abi, address);
